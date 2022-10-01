#Requires -Version 5.1
Using Assembly PresentationCore
Using Assembly PresentationFramework
Using Assembly WindowsBase

Using Namespace System.Collections.Generic
Using Namespace System.Collections.ObjectModel
Using Namespace System.Globalization
Using Namespace System.Reflection
Using Namespace System.Windows
Using Namespace System.Windows.Controls
Using Namespace System.Windows.Data
Using Namespace System.Windows.Input
Using Namespace System.Windows.Markup
Using Namespace System.Windows.Media
Using Namespace System.Windows.Threading

Set-StrictMode -Version Latest




# PowerShell 5 classes are created when the script is parsed, so before the import statements above
# are executed. This means that classes cannot contain any types not loaded by default.
# Therefore, classes have been written with certain parts commented out:
# <# Class TestClass : BaseClass #> {
#   Static [Type] $StaticProperty
#   <# Constructor #> Function TestClass() { }
#   <# [ReturnType] #> Function MemberFunction() { }
# }
# Once the assemblies are loaded, the part below checks if $PSCommandPath is set (which points to the
# currently executing file). If it is, the code of the script itself is read, the two regexes remove the
# comments from the classes, and executes the whole script using Invoke-Expression (which resets
# $PSCommandPath inside).
If (-not [String]::IsNullOrEmpty($PSCommandPath)) {
  (
    # Load the code of the script.
    # Remove the class declaration comments. 
    # '<# Class A : B, C, D #> {' => 'Class A: B, C, D {'
    # Remove constructor and member comments.
    # '<# Static Constructor #> Function A()' => 'Static A()'
    # '<# [A] #> Function B()' => '[A] B()'
    (Get-Content $PSCommandPath -Encoding UTF8) `
    -creplace '^\s*<#\s*(Class\s+\w+(\s*:\s*\w+(\s*,\s*\w+)*)?)\s*#>', '$1' `
    -creplace '^\s*<#\s*((Static\s+)?Constructor|((Hidden\s*)?(Static\s*)?\[[\w\[\]]+\])?)\s*#>\s*Function', '$2$3'
  ) `
  -join [Environment]::NewLine `
  | Invoke-Expression
  Exit
}




# Declares the possible game modes. They can be selected from the menu before restarting a game.
# The 'BoardWidth' defines how many fields in the X direction are shown.
# The 'BoardHeight' defines how many fields in the Y direction are shown.
# The 'MineCount' defines how many mines are randomly placed among the fields.
Set-Variable easyMode ([PSCustomObject] @{
  Name        = 'Easy'
  BoardWidth  = 10
  BoardHeight = 10
  MineCount   = 10
})

Set-Variable mediumMode ([PSCustomObject] @{
  Name        = 'Medium'
  BoardWidth  = 16
  BoardHeight = 16
  MineCount   = 40
})

Set-Variable hardMode ([PSCustomObject] @{
  Name        = 'Hard'
  BoardWidth  = 30
  BoardHeight = 16
  MineCount   = 99
})




# The view model of the main window. An instance of this class is set as the
# DataContext of the window, which means data binding expressions of the window
# will target the properties of the view model.
<# Class ViewModel : DependencyObject #> {
  
  # 2D array that contains a map of all the fields. The first coordinate is X, the
  # second coordinate is Y. This is used to help identify the neighbors of fields.
  Hidden [Field[,]] $BoardMap = (New-Object 'Field[,]' 0, 0)

  # Timer that counts the elapsed seconds of a running game.
  Hidden [DispatcherTimer] $Timer

  # The game title shown in the window and dialogs.
  [String] $Title = 'PowerShell Minesweeper'

  # The number of fields of the game board in the X direction.
  # Contains the board width of the current game mode.
  # The game grid columns of the window are bound to this property.
  Static [DependencyProperty] $BoardWidthProperty = [DependencyProperty]::Register(
    'BoardWidth', [Int32], [ViewModel]
  )

  # The number of fields of the game board in the Y direction.
  # Contains the board height of the current game mode.
  # The game grid rows of the window are bound to this property.
  Static [DependencyProperty] $BoardHeightProperty = [DependencyProperty]::Register(
    'BoardHeight', [Int32], [ViewModel]
  )

  # The current number of unmarked mines on the game board.
  # The mine display in the top right corner of the window is bound to this property.
  Static [DependencyProperty] $MineCountProperty = [DependencyProperty]::Register(
    'MineCount', [Int32], [ViewModel]
  )

  # The number of seconds since the game started.
  # This value is increased by the DispatcherTimer.
  # The time display in the top right corner of the window is bound to this property.
  Static [DependencyProperty] $ElapsedSecondsProperty = [DependencyProperty]::Register(
    'ElapsedSeconds', [Int32], [ViewModel]
  )

  # Observable collection containing all the fields on the board.
  # The game grid of the window is bound to this property.
  # The fields in the game grid are bound to the elements of this property.
  Static [DependencyProperty] $BoardProperty = [DependencyProperty]::Register(
    'Board', [ObservableCollection[Field]], [ViewModel]
  )

  # Determines if the game is currently active. A game is active when the player has not
  # revealed a mine and there are still empty fields hidden (i.e. the game is not over).
  # When this property is set to $false, the timer is stopped.
  # The visibility of the game status display in the top center of the window is bound
  # to this property.
  Static [DependencyProperty] $IsGameActiveProperty = [DependencyProperty]::Register(
    'IsGameActive', [Boolean], [ViewModel], [PropertyMetadata]::new($false, {
      Param ([ViewModel] $this, [DependencyPropertyChangedEventArgs] $e)
      If (-not $e.NewValue) {
        $this.Timer.Stop()
      }
    })
  )

  # Whether the game has been won or not. This property is set when checking the winning
  # conditions in [Field]::Reveal and is bound to the game status display in the top center
  # of the window and determines whether to show a check mark or a cross.
  Static [DependencyProperty] $HasGameBeenWonProperty = [DependencyProperty]::Register(
    'HasGameBeenWon', [Boolean], [ViewModel]
  )

  # The width and height of a displayed field in the game board.
  # The Width and Height properties of the fields as well as the zoom control in the top
  # left of the window are bound to this property.
  Static [DependencyProperty] $FieldSizeProperty = [DependencyProperty]::Register(
    'FieldSize', [Double], [ViewModel],
    (New-Object PropertyMetadata 40.0)
  )

  # The current mode of the game. Also declares that the default mode is 'Easy'.
  # This property is set by the handlers of the mode switches in the main menu and
  # read by handler of the new game menu item.
  Static [DependencyProperty] $ModeProperty = [DependencyProperty]::Register(
    'Mode', [PSCustomObject], [ViewModel],
    (New-Object PropertyMetadata $easyMode)
  )

  # The constructor of the ViewModel initializes the board to an empty collection.
  <# Constructor #> Function ViewModel() {
    $this.SetValue([ViewModel]::BoardProperty, (New-Object 'ObservableCollection[Field]'))
  }

  # Starts a new game by discarding the current game state and setting up the game
  # according to the given mode.
  <# [Void] #> Function StartNewGame([PSCustomObject] $mode) {
    $this.SetValue([ViewModel]::IsGameActiveProperty, $false)
    [ObservableCollection[Field]] $board = $this.GetValue([ViewModel]::BoardProperty)
    [Int32] $oldBoardWidth = $this.GetValue([ViewModel]::BoardWidthProperty)
    [Int32] $oldBoardHeight = $this.GetValue([ViewModel]::BoardHeightProperty)

    # Copy the mode values into their corresponding properties on the ViewModel.
    $this.SetValue([ViewModel]::BoardWidthProperty,  $mode.BoardWidth)
    $this.SetValue([ViewModel]::BoardHeightProperty, $mode.BoardHeight)
    $this.SetValue([ViewModel]::MineCountProperty,   $mode.MineCount)

    # Adjust the board.
    # To reduce the number of views that have to be recreated, check which fields can
    # be removed or have to be added according to the given mode and the currently active one.
    [List[Field]]::new($board).ToArray() `
    | Where-Object {
      # A field has to be removed when one of its coordinates is larger than the
      # current mode's board dimensions.
      $PSItem.X -cge $mode.BoardWidth -or $PSItem.Y -cge $mode.BoardHeight
    } `
    | ForEach-Object {
      Write-Debug "ViewModel::StartNewGame: Removing field at $($PSItem.X), $($PSItem.Y)"
      # Remove all out-of-bounds fields from the board.
      $board.Remove($PSItem)
    }
    ForEach($y In 0 .. ($mode.BoardHeight - 1)) {
      ForEach($x In 0 .. ($mode.BoardWidth - 1)) {
        # Add all fields that have coordinates larger than the previous mode's dimensions.
        If ($x -cge $oldBoardWidth -or $y -cge $oldBoardHeight) {
          Write-Debug "ViewModel::StartNewGame: Adding field at $x, $y"
          $board.Add((New-Object Field $this, $x, $y))
        }
      }
    }

    # Create new board map and reset the fields to their default state (not revealed, etc.).
    # The board map is required in the next section.
    $this.BoardMap = New-Object 'Field[,]' $mode.BoardWidth, $mode.BoardHeight
    ForEach ($field In $board) {
      $field.Reset()
      $this.BoardMap[$field.X, $field.Y] = $field
    }

    # Update the neighbors of each field.
    # This is done by going through every field, reading its coordinates and reading its
    # neighboring fields from the board map.
    ForEach ($field In $board) {
      [List[Field]] $neighbors = New-Object 'List[Field]'
      ForEach ($dy In -1 .. 1) {
        ForEach ($dx In -1 .. 1) {
          [Boolean] $xInBounds = $field.X + $dx -cge 0 -and $field.X + $dx -clt $mode.BoardWidth
          [Boolean] $yInBounds = $field.Y + $dy -cge 0 -and $field.Y + $dy -clt $mode.BoardHeight
          If ($xInBounds -and $yInBounds -and ($dx -cne 0 -or $dy -cne 0)) {
            $neighbors.Add(($this.BoardMap[($field.X + $dx), ($field.Y + $dy)]))
          }
        }
      }
      # Store the field's neighbors inside its neighbors property.
      $field.SetValue([Field]::NeighborsProperty, $neighbors.ToArray())
    }

    # Randomly distribute mines on the board.
    $this.PlaceMines($mode.MineCount)

    # Reset the game status.
    $this.SetValue([ViewModel]::ElapsedSecondsProperty, 0)
    $this.SetValue([ViewModel]::HasGameBeenWonProperty, $false)
    $this.SetValue([ViewModel]::IsGameActiveProperty, $true)
  }

  # Randomly place the given number of mines across the board.
  <# [Void] #> Function PlaceMines([Int32] $mineCount) {
    [Random] $random = New-Object Random
    [Int32] $boardWidth = $this.GetValue([ViewModel]::BoardWidthProperty)
    [Int32] $boardHeight = $this.GetValue([ViewModel]::BoardHeightProperty)
    1 .. $mineCount `
    | ForEach-Object {
      [Boolean] $minePlaced = $false
      Do {
        # Randomly select a field from the board.
        [Field] $field = $this.BoardMap[$random.Next(0, $boardWidth), $random.Next(0, $boardHeight)]
        # Declare the field a mine if it is not one already.
        If (-not $field.GetValue([Field]::IsMineProperty)) {
          Write-Debug "ViewModel::PlaceMines: Placing mine at $($field.X), $($field.Y)."
          $field.SetValue([Field]::IsMineProperty, $true)
          $minePlaced = $true
        }
      } Until ($minePlaced)
    }
  }

  # ScriptBlock that is executed when the player clicks the 'Start New Game' menu item.
  [ScriptBlock] $OnStartNewGame = {
    Param ([ViewModel] $this)
    # Check if a game is currently underway and ask the player if it should be aborted.
    If ($this.Timer.IsEnabled) {
      [MessageBoxResult] $questionResult = [MessageBox]::Show(
        'Do you really want to start a new game?',
        $this.Title,
        [MessageBoxButton]::YesNo,
        [MessageBoxImage]::Question
      )
      If ($questionResult -cne [MessageBoxResult]::Yes) {
        # The player does not want to abort the game.
        Return
      }
    }
    $this.StartNewGame($this.GetValue([ViewModel]::ModeProperty))
  }

  # ScriptBlock that is executed when the player clicks the 'Easy' menu item.
  [ScriptBlock] $OnSetModeEasy = {
    Param ([ViewModel] $this)
    $this.SetValue([ViewModel]::ModeProperty, $easyMode)
  }

  # ScriptBlock that is executed when the player clicks the 'Medium' menu item.
  [ScriptBlock] $OnSetModeMedium = {
    Param ([ViewModel] $this)
    $this.SetValue([ViewModel]::ModeProperty, $mediumMode)
  }

  # ScriptBlock that is executed when the player clicks the 'Hard' menu item.
  [ScriptBlock] $OnSetModeHard = {
    Param ([ViewModel] $this)
    $this.SetValue([ViewModel]::ModeProperty, $hardMode)
  }

}




# The view model of a field in the game grid. Contained in the [ViewModel]::Board property.
<# Class Field : DependencyObject #> {

  # Reference to the parent view model of the window.
  [ViewModel] $ViewModel

  # The X coordinate of the field on the game board.
  # The Grid.Column property of the field on the game grid is bound to this property.
  [Int32] $X

  # The Y coordinate of the field on the game board.
  # The Grid.Row property of the field on the game grid is bound to this property.
  [Int32] $Y

  # Determines whether this field contains a mine.
  # The Text and Background properties of the field on the window are
  # bound to this property.
  Static [DependencyProperty] $IsMineProperty = [DependencyProperty]::Register(
    'IsMine', [Boolean], [Field]
  )

  # Determines whether the contents of the field should be shown to the player.
  # The Text and Background properties of the field on the window are
  # bound to this property. Furthermore, when this property is set to $true,
  # the Timer will be started if it was not active already.
  Static [DependencyProperty] $IsRevealedProperty = [DependencyProperty]::Register(
    'IsRevealed', [Boolean], [Field], [PropertyMetadata]::new($false, {
      Param ([Field] $this, [DependencyPropertyChangedEventArgs] $e)
      If ($e.NewValue) {
        $this.ViewModel.Timer.Start()
      }
    })
  )

  # Contains the neighboring fields of this field.
  # The Text property of the field on the window is bound to this property. 
  Static [DependencyProperty] $NeighborsProperty = [DependencyProperty]::Register(
    'Neighbors', [Field[]], [Field]
  )

  # When the player clicks on the game fields on the window and holds the mouse button down,
  # the field under the cursor (if only one mouse button is down) or the neighboring fields
  # (if both mouse buttons are down) are highlighted. This property determines whether the
  # current field should be shown highlighted if it has not been revealed yet.
  # The Background property of the field on the window is bound to this property.
  Static [DependencyProperty] $IsHighlightedProperty = [DependencyProperty]::Register(
    'IsHighlighted', [Boolean], [Field]
  )

  # Contains the currently pressed mouse buttons and whether a click has already been
  # performed. Once both buttons have been down and one has been released, releasing the
  # other mouse button must not perform another click. Therefore, the ClickAllowed flag
  # is used to track this.
  Static [DependencyProperty] $MouseStateProperty = [DependencyProperty]::Register(
    'MouseState', [MouseState], [Field],
    [PropertyMetadata]::new([MouseState]::NoButtonDown, {
      Param ([Field] $this, [DependencyPropertyChangedEventArgs] $e)
      # Highlight this field if only one button is down.
      $this.SetValue(
        [Field]::IsHighlightedProperty,
        ($e.NewValue -band [MouseState]::BothButtonsDown) -ceq [MouseState]::LeftButtonDown -xor `
        ($e.NewValue -band [MouseState]::BothButtonsDown) -ceq [MouseState]::RightButtonDown
      )
      # Highlight the neighbors if all buttons are down.
      $this.GetValue([Field]::NeighborsProperty) `
      | ForEach-Object {
        $PSItem.SetValue(
          [Field]::IsHighlightedProperty,
          ($e.NewValue -band [MouseState]::BothButtonsDown) -ceq [MouseState]::BothButtonsDown
        )
      }
    })
  )

  # Contains the current mark of the field. Normally a field is not marked, but if the player
  # right-clicks once, it will be marked as a mine with [FieldMark]::MineMark, if the player
  # right-clicks again, it will be marked with a question mark with [FieldMark]::QuestionMark
  # and another right-click removed the mark again.
  # If a mark is placed on a field, the timer will be started if it was not already.
  Static [DependencyProperty] $MarkProperty = [DependencyProperty]::Register(
    'Mark', [FieldMark], [Field], [PropertyMetadata]::new([FieldMark]::NoMark, {
      Param ([Field] $this, [DependencyPropertyChangedEventArgs] $e)
      If ($e.NewValue -cne [FieldMark]::NoMark) {
        $this.ViewModel.Timer.Start()
      }
    })
  )

  <# Constructor #> Function Field([ViewModel] $viewModel, [Int32] $x, [Int32] $y) {
    $this.ViewModel = $viewModel
    $this.X = $x
    $this.Y = $y
  }

  # Reset the field state by making it empty, hidden and unmarked.
  <# [Void] #> Function Reset() {
    $this.SetValue([Field]::IsMineProperty, $false)
    $this.SetValue([Field]::IsRevealedProperty, $false)
    $this.SetValue([Field]::MarkProperty, [FieldMark]::NoMark)
  }

  # Reveal this field. The skipChecks parameter is used when it is not required
  # to check for game-ending conditions (for example while revealing neighbors).
  # This function is executed by the left-click handler.
  <# [Void] #> Function Reveal([Boolean] $skipChecks) {
    If (
      -not $this.ViewModel.GetValue([ViewModel]::IsGameActiveProperty) -or `
      $this.GetValue([Field]::IsRevealedProperty) -or `
      $this.GetValue([Field]::MarkProperty) -cne [FieldMark]::NoMark
    ) {  Return }

    #If the game just started and the click was on a mine, move the mine.
    [Boolean] $isMine = $this.GetValue([Field]::IsMineProperty)
    If (-not $skipChecks -and -not $this.ViewModel.Timer.IsEnabled -and $isMine) {
      Write-Debug 'Field::Reveal: First click was on mine.'
      # Place one more mine on the board without setting this field as empty,
      # to ensure that this field is not marked as a mine again.
      $this.ViewModel.PlaceMines(1)
      # Declare this field empty.
      $isMine = $false
      $this.SetValue([Field]::IsMineProperty, $false)
    }

    # Reveal the field.
    $this.SetValue([Field]::IsRevealedProperty, $true)

    # Reveal neighbors if the field is empty.
    [Field[]] $neighbors = $this.GetValue([Field]::NeighborsProperty)
    [Int32] $mineCount = @(
      $neighbors `
      | Where-Object {
        $PSItem.GetValue([Field]::IsMineProperty)
      }
    ).Count
    If (-not $isMine -and $mineCount -ceq 0) {
      $neighbors `
      | ForEach-Object {
        # Reveal the neighbors without checking the state.
        $PSItem.Reveal($true)
      }
    }

    # End the game if a mine was revealed.
    If (-not $skipChecks -and $isMine) {
      Write-Debug 'Field::Reveal: Revealed a mine. Game over.'
      $this.ViewModel.SetValue([ViewModel]::IsGameActiveProperty, $false)
      Return
    }

    #End the game if only the mines are remaining.
    If (-not $skipChecks) {
      [ObservableCollection[Field]] $board = $this.ViewModel.GetValue([ViewModel]::BoardProperty)
      # Count the number of fields that are empty and have not been revealed yet.
      [Int32] $hiddenEmptyFieldCount = @(
        $board `
        | Where-Object {
          -not $PSItem.GetValue([Field]::IsRevealedProperty) -and `
          -not $PSItem.GetValue([Field]::IsMineProperty)
        }
      ).Count
      If ($hiddenEmptyFieldCount -ceq 0) {
        # There are no more empty fields that are not revealed remaining.
        # This means there are only mines left, the player has won.
        $board `
        | Where-Object {
          -not $PSItem.GetValue([Field]::IsRevealedProperty)
        } `
        | ForEach-Object {
          $PSItem.SetValue([Field]::MarkProperty, [FieldMark]::MineMark)
        }
        Write-Debug 'Field::Reveal: Only mines remaining. Game won.'
        $this.ViewModel.SetValue([ViewModel]::HasGameBeenWonProperty, $true)
        $this.ViewModel.SetValue([ViewModel]::IsGameActiveProperty, $false)
        $this.ViewModel.SetValue([ViewModel]::MineCountProperty, 0)
      }
    }
  }

  # Switches the mark on the current field if it is hidden.
  # No mark => Mine mark => Question mark => No mark => ...
  # This function is executed by the right-click handler.
  <# [Void] #> Function ToggleMark() {
    If (
      -not $this.ViewModel.GetValue([ViewModel]::IsGameActiveProperty) -or `
      $this.GetValue([Field]::IsRevealedProperty)
    ) { Return }
    # Switch to the next mark.
    [FieldMark] $newMark = ($this.GetValue([Field]::MarkProperty) + 1) % [FieldMark]::MaximumMark
    $this.SetValue([Field]::MarkProperty, $newMark)
    # When the player marks a mine, the mine count display has to be adjusted.
    [Int32] $delta =
      If ($newMark -ceq [FieldMark]::MineMark) {
        # Marking a mine decreases the mine count by one.
        -1
      } ElseIf ($newMark -ceq [FieldMark]::QuestionMark) {
        # Removing the mine mark (by switching to a question mark) increases the mine count again.
        1
      } Else {
        # Switching to any other mark does not affect the mine count.
        0
      }
    $this.ViewModel.SetValue(
      [ViewModel]::MineCountProperty,
      $this.ViewModel.GetValue([ViewModel]::MineCountProperty) + $delta
    )
  }

  # When clicking with both mouse buttons on an empty field, its neighbors will be revealed
  # if all mines in the neighbors have been marked.
  # This function is executed by the both-click handler.
  <# [Void] #> Function RevealOthers() {
    If (
      -not $this.ViewModel.GetValue([ViewModel]::IsGameActiveProperty) -or `
      -not $this.GetValue([Field]::IsRevealedProperty)
    ) { Return }

    # Count the number of mines and mine marks in the neighbors.
    [Field[]] $neighbors = $this.GetValue([Field]::NeighborsProperty)
    [Int32] $mineCount = 0
    [Int32] $mineMarkCount = 0
    $neighbors `
    | ForEach-Object {
      If ($PSItem.GetValue([Field]::IsMineProperty)) {
        $mineCount++
      }
      If ($PSItem.GetValue([Field]::MarkProperty) -ceq [FieldMark]::MineMark) {
        $mineMarkCount++
      }
    }

    Write-Debug "Field::RevealOthers: Mines = $mineCount, Flags = $mineMarkCount"
    If ($mineCount -ceq $mineMarkCount) {
      # The mine and mine mark count agree, so we can reveal the neighboring fields.
      $neighbors `
      | Where-Object {
        $PSItem.GetValue([Field]::MarkProperty) -ceq [FieldMark]::NoMark
      } `
      | ForEach-Object {
        $PSItem.Reveal($false)
      }
    }
  }

  # ScriptBlock that is executed when the user presses the left mouse button over a field.
  [ScriptBlock] $OnMouseLeftButtonDown = {
    Param ([Field] $this)
    [MouseState] $mouseState = $this.GetValue([Field]::MouseStateProperty)
    # Set the flag that indicates whether a click is allowed only when the right button was up.
    [MouseState] $clickAllowed =
      If ($mouseState -ceq [MouseState]::NoButtonDown) {
        [MouseState]::ClickAllowed
      } Else {
        [MouseState]::NoButtonDown
      }
    $this.SetValue(
      [Field]::MouseStateProperty,
      $mouseState -bor [MouseState]::LeftButtonDown -bor $clickAllowed
    )
  }

  # ScriptBlock that is executed when the user releases the left mouse button over a field.
  [ScriptBlock] $OnMouseLeftButtonUp = {
    Param ([Field] $this)
    [MouseState] $mouseState = $this.GetValue([Field]::MouseStateProperty)
    # Ensure that a click is currently allowed.
    If ($mouseState -band [MouseState]::ClickAllowed) {
      If (($mouseState -band [MouseState]::BothButtonsDown) -ceq [MouseState]::BothButtonsDown) {
        # If it is, and both buttons have been pressed, try to reveal the field's neighbors.
        Write-Debug "Field::OnMouseLeftButtonUp: Click L+R on $($this.X), $($this.Y)."
        $this.RevealOthers()
      } ElseIf ($mouseState -band [MouseState]::LeftButtonDown) {
        # If it is, but only the left button was pressed, try to reveal the field.
        Write-Debug "Field::OnMouseLeftButtonUp: Click L on $($this.X), $($this.Y)."
        $this.Reveal($false)
      }
    }
    # Remove the left mouse button flag since it was just released and also the click allowed flag
    # since a click was just performed if it was allowed.
    $this.SetValue(
      [Field]::MouseStateProperty,
      $mouseState -band -bnot ([MouseState]::LeftButtonDown -bor [MouseState]::ClickAllowed)
    )
  }

  # ScriptBlock that is executed when the user presses the right mouse button over a field.
  [ScriptBlock] $OnMouseRightButtonDown = {
    Param ([Field] $this)
    [MouseState] $mouseState = $this.GetValue([Field]::MouseStateProperty)
    # Set the flag that indicates whether a click is allowed only when the left button was up.
    [MouseState] $clickAllowed =
      If ($mouseState -ceq [MouseState]::NoButtonDown) {
        [MouseState]::ClickAllowed
      } Else {
        [MouseState]::NoButtonDown
      }
    $this.SetValue(
      [Field]::MouseStateProperty,
      $mouseState -bor [MouseState]::RightButtonDown -bor $clickAllowed
    )
  }

  # ScriptBlock that is executed when the user releases the right mouse button over a field.
  [ScriptBlock] $OnMouseRightButtonUp = {
    Param ([Field] $this)
    [MouseState] $mouseState = $this.GetValue([Field]::MouseStateProperty)
    # Ensure that a click is currently allowed.
    If ($mouseState -band [MouseState]::ClickAllowed) {
      If (($mouseState -band [MouseState]::BothButtonsDown) -ceq [MouseState]::BothButtonsDown) {
        # If it is, and both buttons have been pressed, try the reveal the field's neighbors.
        Write-Debug "Field::OnMouseRightButtonUp: Click L+R on $($this.X), $($this.Y)."
        $this.RevealOthers()
      } ElseIf ($mouseState -band [MouseState]::RightButtonDown) {
        # If it is, but only the right button was pressed, try to toggle the mark on the field.
        Write-Debug "Field::OnMouseRightButtonUp: Click R on $($this.X), $($this.Y)."
        $this.ToggleMark()
      }
    }
    # Remove the right mouse button flag since it was just released and also the click allowed flag
    # since a click was just performed if it was allowed.
    $this.SetValue(
      [Field]::MouseStateProperty,
      $mouseState -band -bnot ([MouseState]::RightButtonDown -bor [MouseState]::ClickAllowed)
    )
  }

  # ScriptBlock that is executed when the mouse pointer has entered the current field.
  [ScriptBlock] $OnMouseEnter = {
    Param ([Field] $this, [Border] $sender, [MouseEventArgs] $e)
    # If the mouse has entered while the left button was down, set the left button flag.
    [MouseState] $leftState =
      If ($e.LeftButton -ceq [MouseButtonState]::Pressed) {
        [MouseState]::LeftButtonDown
      } Else {
        [MouseState]::NoButtonDown
      }
      # If the mouse has entered while the right button was down, set the right button flag.
    [MouseState] $rightState =
      If ($e.RightButton -ceq [MouseButtonState]::Pressed) {
        [MouseState]::RightButtonDown
      } Else {
        [MouseState]::NoButtonDown
      }
    # Update the mouse state of the current field.
    # Note that the click allowed flag is not set, since it should not be possible to drag
    # the mouse across the field and still click, because this is how the player expects to
    # abort a click.
    $this.SetValue(
      [Field]::MouseStateProperty,
      $leftState -bor $rightState
    )
  }

  # ScriptBlock that is executed when the mouse pointer has left the current field.
  [ScriptBlock] $OnMouseLeave = {
    Param ([Field] $this)
    # Reset the mouse state to indicate no button is pressed.
    $this.SetValue([Field]::MouseStateProperty, [MouseState]::NoButtonDown)
  }

}




# The main window declared as XAML.
[Window] $window = [XamlReader]::Parse((@'
  <Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
          xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
          xmlns:ps="clr-namespace:;assembly="
          Title="{Binding Title}"
          SizeToContent="WidthAndHeight"
          ResizeMode="NoResize"
  >

    <Window.Resources>

      <!-- An instance of the ScriptBlockConverter defined below. It is used to
           convert between types using a ScriptBlock. -->
      <ps:ScriptBlockConverter x:Key="ScriptBlock" />

      <!-- Style that changes the color of the mine number in a field. -->
      <Style x:Key="FieldTextStyle" TargetType="{x:Type TextBlock}">
        <Style.Triggers>
          <Trigger Property="Text" Value="0">
            <Setter Property="Visibility" Value="Hidden" />
          </Trigger>
          <Trigger Property="Text" Value="1">
            <Setter Property="Foreground" Value="RoyalBlue" />
          </Trigger>
          <Trigger Property="Text" Value="2">
            <Setter Property="Foreground" Value="ForestGreen" />
          </Trigger>
          <Trigger Property="Text" Value="3">
            <Setter Property="Foreground" Value="Firebrick" />
          </Trigger>
          <Trigger Property="Text" Value="4">
            <Setter Property="Foreground" Value="MediumBlue" />
          </Trigger>
          <Trigger Property="Text" Value="5">
            <Setter Property="Foreground" Value="Brown" />
          </Trigger>
          <Trigger Property="Text" Value="6">
            <Setter Property="Foreground" Value="DarkCyan" />
          </Trigger>
          <Trigger Property="Text" Value="7">
            <Setter Property="Foreground" Value="DarkSlateGray" />
          </Trigger>
          <Trigger Property="Text" Value="8">
            <Setter Property="Foreground" Value="DimGray" />
          </Trigger>
        </Style.Triggers>
      </Style>

      <!-- Brush used as the background of a field when a mine has been
           revealed by the player (i.e. BOOM!). -->
      <RadialGradientBrush x:Key="ExplodedMineBrush">
        <GradientStop Color="Crimson" Offset="0.5" />
        <GradientStop Color="Transparent" Offset="1.0" />
      </RadialGradientBrush>

      <!-- Brush used as the background of a field when a mine has been
           marked as such by the player. -->
      <RadialGradientBrush x:Key="DefusedMineBrush">
        <GradientStop Color="LimeGreen" Offset="0.5" />
        <GradientStop Color="LightGray" Offset="1.0" />
      </RadialGradientBrush>

      <!-- Brush used when the player marked an empty field as a mine. -->
      <RadialGradientBrush x:Key="EmptyMineMarkBrush">
        <GradientStop Color="LightPink" Offset="0.5" />
        <GradientStop Color="LightGray" Offset="1.0" />
      </RadialGradientBrush>

      <!-- Style applied to the controls and displays at the top
           of the window. It makes them appear black and round. -->
      <Style x:Key="RoundedBorderStyle" TargetType="{x:Type Border}">
        <Setter Property="Padding" Value="2 2 5 2" />
        <Setter Property="Background" Value="Black" />
        <Setter Property="Control.Foreground" Value="LightGray" />
        <Setter Property="BorderBrush" Value="Black" />
        <Setter Property="BorderThickness" Value="2" />
        <Setter Property="CornerRadius" Value="{
          Binding ActualHeight,
          RelativeSource={RelativeSource Self},
          Converter={StaticResource ScriptBlock},
          ConverterParameter=
            Param ([Double] $height)
            $height / 2.0
        }" />
        <Setter Property="TextBlock.FontSize" Value="20" />
      </Style>
    </Window.Resources>

    <Window.CommandBindings>
      <!-- Binding for the "Start New Game" menu item. -->
      <CommandBinding Command="New" Executed="{ps:RunScriptBlock OnStartNewGame}" />
    </Window.CommandBindings>

    <DockPanel>
      <Menu DockPanel.Dock="Top">
        <MenuItem Header="_Game">

          <!-- Clicking this menu item will abort the current game and start a new one. -->
          <MenuItem Header="Start _New Game" Command="New" />
          <Separator />

          <!-- Clicking this menu item will set the game mode to "Easy". -->
          <MenuItem Header="_Easy"
                    Click="{ps:RunScriptBlock OnSetModeEasy}"
                    IsChecked="{
                      Binding Mode,
                      Converter={StaticResource ScriptBlock},
                      ConverterParameter='
                        Param ([PSCustomObject] $mode)
                        $mode.Name -ceq &quot;Easy&quot;
                      '
                    }"
          />

          <!-- Clicking this menu item will set the game mode to "Medium". -->
          <MenuItem Header="_Medium"
                    Click="{ps:RunScriptBlock OnSetModeMedium}"
                    IsChecked="{
                      Binding Mode,
                      Converter={StaticResource ScriptBlock},
                      ConverterParameter='
                        Param ([PSCustomObject] $mode)
                        $mode.Name -ceq &quot;Medium&quot;
                      '
                    }"
          />

          <!-- Clicking this menu item will set the game mode to "Hard". -->
          <MenuItem Header="_Hard"
                    Click="{ps:RunScriptBlock OnSetModeHard}"
                    IsChecked="{
                      Binding Path=Mode,
                      Converter={StaticResource ScriptBlock},
                      ConverterParameter='
                        Param ([PSCustomObject] $mode)
                        $mode.Name -ceq &quot;Hard&quot;
                      '
                    }"
          />
        </MenuItem>
      </Menu>

      <!-- Contains the zoom control, game status, mine and time display. -->
      <DockPanel DockPanel.Dock="Top" Margin="5">

        <!-- Contains the slider used to zoom in or out. -->
        <Border DockPanel.Dock="Left" Style="{StaticResource RoundedBorderStyle}">
          <StackPanel Orientation="Horizontal">
            <TextBlock FontFamily="Consolas" Margin="0 0 5 0">🔍</TextBlock>
            <Slider Value="{Binding FieldSize}" Width="50" Minimum="30" Maximum="60"
                    IsSnapToTickEnabled="True" TickFrequency="10" VerticalAlignment="Center"
            />
          </StackPanel>
        </Border>

        <!-- Shows the number of elapsed seconds since game start. -->
        <Border DockPanel.Dock="Right" Style="{StaticResource RoundedBorderStyle}" Margin="10 0 0 0">
          <StackPanel Orientation="Horizontal">
            <TextBlock FontFamily="Consolas" Margin="0 0 5 0">⌚</TextBlock>
            <TextBlock FontFamily="Consolas" Text="{Binding ElapsedSeconds, StringFormat={}{0:D4}}" />
          </StackPanel>
        </Border>

        <!-- Shows the number of unmarked mines. -->
        <Border DockPanel.Dock="Right" Style="{StaticResource RoundedBorderStyle}" Margin="10 0 0 0">
          <StackPanel Orientation="Horizontal">
            <TextBlock FontFamily="Consolas" Margin="0 0 5 0">⛭</TextBlock>
            <TextBlock FontFamily="Consolas" Text="{
              Binding MineCount,
              Converter={StaticResource ScriptBlock},
              ConverterParameter='
                Param ([Int32] $mineCount)
                [Math]::Max($mineCount, 0).ToString(&quot;D2&quot;)
              '
            }" />
          </StackPanel>
        </Border>

        <!-- Displays a check mark if the game was won, or a cross if the game was lost. -->
        <TextBlock VerticalAlignment="Center" TextAlignment="Center" 
                   FontWeight="Bold" FontFamily="Consolas" FontSize="20"
                   Text="{
                    Binding HasGameBeenWon,
                    Converter={StaticResource ScriptBlock},
                    ConverterParameter='
                      Param ([Boolean] $hasGameBeenWon)
                      If ($hasGameBeenWon) { &quot;✓&quot; } Else { &quot;✗&quot; }
                    '
                   }"
                   Foreground="{
                    Binding HasGameBeenWon,
                    Converter={StaticResource ScriptBlock},
                    ConverterParameter='
                      Param ([Boolean] $hasGameBeenWon)
                      If ($hasGameBeenWon) { [Brushes]::Green } Else { [Brushes]::Crimson }
                    '
                   }"
                   Visibility="{
                    Binding IsGameActive,
                    Converter={StaticResource ScriptBlock},
                    ConverterParameter='
                      Param ([Boolean] $isGameActive)
                      If ($isGameActive) { [Visibility]::Collapsed } Else { [Visibility]::Visible }
                    '
                   }"
        />
      </DockPanel>

      <!-- Contains the game board. -->
      <Border BorderBrush="Black" BorderThickness="1" Margin="5">
        <ItemsControl ItemsSource="{Binding Board}">
          <ItemsControl.ItemsPanel>
            <ItemsPanelTemplate>
              <!-- The panel of the game board is a grid, then the individual fields can be laid out
                   using their X and Y coordinates bound to the Grid's Row and Column properties. -->
              <Grid ps:GridEx.Columns="{Binding BoardWidth}"
                    ps:GridEx.Rows="{Binding BoardHeight}">
              </Grid>
            </ItemsPanelTemplate>
          </ItemsControl.ItemsPanel>
          <ItemsControl.ItemContainerStyle>
            <!-- Style that sets the Row and Column property of the field. This might come as a surprise
                 that it has to be set here and not on the first child of the template below. The reason
                 is that the immediate child of the Grid are not the DataTemplate children, they are
                 wrapped inside an extra item. <Grid><Item>Stuff from the template</Item></Grid>. So you
                 see why the Row and Column property has to go on the Item. -->
            <Style>
              <Setter Property="Grid.Column" Value="{Binding X}" />
              <Setter Property="Grid.Row"    Value="{Binding Y}" />
            </Style>
          </ItemsControl.ItemContainerStyle>
          <ItemsControl.ItemTemplate>
            <DataTemplate>
              <!-- The view for a field. This template is bound to the [Field] class.
                   It consists of nothing but a Border with a TextBlock child.
                   All mouse actions are performed on the Border. -->
              <Border Width="{Binding ViewModel.FieldSize}"
                      Height="{Binding ActualWidth, RelativeSource={RelativeSource Self}}"
                      MouseLeftButtonDown="{ps:RunScriptBlock OnMouseLeftButtonDown}"
                      MouseLeftButtonUp="{ps:RunScriptBlock OnMouseLeftButtonUp}"
                      MouseRightButtonDown="{ps:RunScriptBlock OnMouseRightButtonDown}"
                      MouseRightButtonUp="{ps:RunScriptBlock OnMouseRightButtonUp}"
                      MouseEnter="{ps:RunScriptBlock OnMouseEnter}"
                      MouseLeave="{ps:RunScriptBlock OnMouseLeave}"
                      BorderBrush="Black"
                      BorderThickness="1"
              >
                <Border.Background>
                  <MultiBinding Converter="{StaticResource ScriptBlock}"
                                ConverterParameter="{x:Static ps:ScriptBlocks.FieldBackground}"
                  >
                    <Binding Path="IsMine" />
                    <Binding Path="IsRevealed" />
                    <Binding Path="Mark" />
                    <Binding Path="IsHighlighted" />
                    <Binding Path="ViewModel.IsGameActive" />
                    <Binding Source="{StaticResource ExplodedMineBrush}" />
                    <Binding Source="{StaticResource DefusedMineBrush}" />
                    <Binding Source="{StaticResource EmptyMineMarkBrush}" />
                  </MultiBinding>
                </Border.Background>
                <!-- The TextBlock is wrapped inside a Viewbox so that it scales to fit the
                     available field space without having to mess around with FontSize. -->
                <Viewbox>
                  <TextBlock Style="{StaticResource FieldTextStyle}">
                    <TextBlock.Text>
                      <MultiBinding Converter="{StaticResource ScriptBlock}"
                                    ConverterParameter="{x:Static ps:ScriptBlocks.FieldText}"
                      >
                        <Binding Path="IsMine" />
                        <Binding Path="IsRevealed" />
                        <Binding Path="Neighbors" />
                        <Binding Path="Mark" />
                        <Binding Path="ViewModel.IsGameActive" />
                      </MultiBinding>
                    </TextBlock.Text>
                  </TextBlock>
                </Viewbox>
              </Border>
            </DataTemplate>
          </ItemsControl.ItemTemplate>
        </ItemsControl>
      </Border>
    </DockPanel>

  </Window>
'@ `
-creplace 'clr-namespace:;assembly=', "`$0$([ViewModel].Assembly.FullName)"))




[ViewModel] $viewModel = New-Object ViewModel
$viewModel.Timer = New-Object DispatcherTimer -Property @{
  Interval = New-TimeSpan -Seconds 1
}
$window.DataContext = $viewModel

# Executed once a second when the game is started.
# Increases the number of elapsed seconds.
$viewModel.Timer.add_Tick({
  If ($viewModel.GetValue([ViewModel]::IsGameActiveProperty)) {
    [Int32] $elapsedSeconds = $viewModel.GetValue([ViewModel]::ElapsedSecondsProperty)
    $viewModel.SetValue([ViewModel]::ElapsedSecondsProperty, $elapsedSeconds + 1)
  }
})

# Executed when the application window was loaded.
# Starts a new game with the default mode.
$window.add_Loaded({
  $viewModel.StartNewGame($viewModel.GetValue([ViewModel]::ModeProperty))
})

#Start the game.
[Application] $application = New-Object Application
$application.ShutdownMode = [ShutDownMode]::OnMainWindowClose
$application.Run($window) | Out-Null




# Contains ScriptBlocks used for data binding in the game window.
<# Class ScriptBlocks #> {

  # Bound to the Text property of a field in the game window.
  Static [ScriptBlock] $FieldText = {
    Param (
      [Boolean] $isMine,
      [Boolean] $isRevealed,
      [Field[]] $neighbors,
      [FieldMark] $mark,
      [Boolean] $isGameActive
    )

    # Handle marked fields (visible when game active).
    If ($isGameActive -and -not $isRevealed) {
      If ($mark -ceq [FieldMark]::MineMark) {
        Return '⛿'
      } ElseIf ($mark -ceq [FieldMark]::QuestionMark) {
        Return '?'
      }
    }
    
    # Handle revealed fields (also visible when game over).
    If (-not $isGameActive -or $isRevealed) {
      If ($isMine) {
        Return '⛭'
      }
      
      # Count the number of mines in the neighboring fields.
      Return "$(@(
        $neighbors `
        | Where-Object {
          $PSItem.GetValue([Field]::IsMineProperty)
        }
      ).Count)"
    }

    Return [String]::Empty
  }

  # Bound to the Background property of a field in the game window.
  Static [ScriptBlock] $FieldBackground = {
    Param (
      [Boolean] $isMine,
      [Boolean] $isRevealed,
      [FieldMark] $mark,
      [Boolean] $isHighlighted,
      [Boolean] $isGameActive,
      [RadialGradientBrush] $explodedMineBrush,
      [RadialGradientBrush] $defusedMineBrush,
      [RadialGradientBrush] $emptyMineMarkBrush
    )

    # Handle revealed fields.
    If ($isRevealed) {
      # If a mine has been revealed, show it as exploded.
      If ($isMine) {
        Return $explodedMineBrush
      }

      Return [Brushes]::Transparent
    }

    # Handle game-over situation.
    If (-not $isGameActive) {
      # Handle fields that are marked as mines.
      If ($mark -ceq [FieldMark]::MineMark) {
        # If the player has successfully marked a mine as such, show it as defused.
        If ($isMine) {
          Return $defusedMineBrush
        }
        
        # If the player has marked an empty field as a mine, show the mistake.
        Return $emptyMineMarkBrush
      }

      # If the field was not touched by the player.
      Return [Brushes]::LightGray
    }

    # Handle fields that are highlighted by a mouse press.
    If ($isHighlighted) {
      Return [Brushes]::ForestGreen
    }

    # Otherwise the game is on, and the field has not been touched.
    Return [Brushes]::PaleGreen
  }

}




# Value converter that uses ScriptBlocks to compute the converted value.
<# Class ScriptBlockConverter : IValueConverter, IMultiValueConverter #> {

  # To avoid repeatedly creating the same ScriptBlocks over and over again,
  # stored them in a Hashtable for quick lookup.
  Hidden Static [Hashtable] $ScriptBlockCache = (New-Object Hashtable)

  # Create a ScriptBlock from the parameter passed into the converter.
  <# Hidden [ScriptBlock] #> Function GetScriptBlock([Object] $parameter) {

    # If a ScriptBlock was already provided (via {x:Static}), use it.
    If ($parameter -is [ScriptBlock]) {
      Return $parameter
    }

    [String] $parameterString = $parameter -as [String]
    If (-not [String]::IsNullOrWhitespace($parameterString)) {
      # Check if the ScriptBlock is already cached.
      If ([ScriptBlockConverter]::ScriptBlockCache.ContainsKey($parameterString)) {
        Return [ScriptBlockConverter]::ScriptBlockCache[$parameterString]
      }
      # Otherwise create a new ScriptBlock from the code and cache it.
      [ScriptBlock] $scriptBlock = [ScriptBlock]::Create($parameterString)
      [ScriptBlockConverter]::ScriptBlockCache.Add($parameterString, $scriptBlock)
      Return $scriptBlock
    }
    
    Throw [InvalidOperationException] "Missing ScriptBlock parameter."
  }

  # Handles single-value conversions.
  <# [Object] #> Function Convert([Object] $value, [Type] $targetType, [Object] $parameter, [CultureInfo] $culture) {
    [Object] $result = $this.GetScriptBlock($parameter).InvokeReturnAsIs($value)
    # ScriptBlocks almost always return PSObjects. Unwrap them.
    If ($result -is [PSObject]) {
      $result = $result.PSObject.BaseObject
    }
    Return $result
  }

  <# [Object] #> Function ConvertBack([Object] $value, [Type] $targetType, [Object] $parameter, [CultureInfo] $culture) {
    Throw [NotSupportedException]
  }

  # Handles multi-value conversions.
  <# [Object] #> Function Convert([Object[]] $values, [Type] $targetType, [Object] $parameter, [CultureInfo] $culture) {
    [Object]$result = $this.GetScriptBlock($parameter).InvokeReturnAsIs($values)
    # ScriptBlocks almost always return PSObjects. Unwrap them.
    If ($result -is [PSObject]) {
      $result = $result.PSObject.BaseObject
    }
    Return $result
  }

  <# [Object[]] #> Function ConvertBack([Object] $value, [Type[]] $targetTypes, [Object] $parameter, [CultureInfo] $culture) {
    Throw [NotSupportedException]
  }

}




# Markup Extension {ps:RunScriptBlock} that can be used to bind events to ScriptBlocks.
<# Class RunScriptBlockExtension : MarkupExtension #> {

  Hidden Static [PropertyInfo] $SingleWorkerProperty
  Hidden Static [MethodInfo]   $AttachToRootItemMethod
  Hidden Static [MethodInfo]   $RawValueMethod
  [PropertyPath]               $Path

  # The extension uses private API to parse a property path.
  # This static constructor fetches the pieces using reflection.
  <# Static Constructor #> Function RunScriptBlockExtension() {
    # A PropertyPath uses an internal type called PropertyPathWorker to do the parsing.
    # The worker is exposed through the internal property SingleWorker.
    [RunScriptBlockExtension]::SingleWorkerProperty = [PropertyPath].GetProperty(
      'SingleWorker', [BindingFlags]::NonPublic -bor [BindingFlags]::Instance
    )
    # The worker has a method AttachToRootItem, which is used to give the worker the root
    # item for the path to resolve.
    [RunScriptBlockExtension]::AttachToRootItemMethod =
      [RunScriptBlockExtension]::SingleWorkerProperty.PropertyType.GetMethod(
        'AttachToRootItem', [BindingFlags]::NonPublic -bor [BindingFlags]::Instance
      )
    # The worker has another method RawValue, which returns the item the path has been resolved
    # to relative to the root item.
    [RunScriptBlockExtension]::RawValueMethod =
      [RunScriptBlockExtension]::SingleWorkerProperty.PropertyType.GetMethod(
        'RawValue', [BindingFlags]::NonPublic -bor [BindingFlags]::Instance, $null, [Type]::EmptyTypes, @()
      )
  }

  # Constructor that is invoked when the extension is created.
  # The path given is the property path that should be resolved.
  # E.g. {ps:RunScriptBlock A.B.C} the path is the string "A.B.C".
  <# Constructor #> Function RunScriptBlockExtension([String] $path) {
    $this.Path = New-Object PropertyPath $path
  }

  # Create an event handler for the given event.
  <# [Object] #> Function ProvideValue([IServiceProvider] $provider) {
    # Fetch the service that gives use information about the expected result.
    [IProvideValueTarget] $provideValueTarget = $provider.GetService([IProvideValueTarget])
    # In our case we can assume the extension is only bound to event targets.
    [EventInfo] $eventInfo = $provideValueTarget.TargetProperty
    # Create a delegate for the expected event handler, and execute the
    # HandleEvent method below when it occurs.
    Return [Delegate]::CreateDelegate(
      $eventInfo.EventHandlerType,
      $this, 
      [RunScriptBlockExtension].GetMethod('HandleEvent')
    )
  }

  # Method executed by the event handler that executes the actual ScriptBlock.
  <# Hidden [Void] #> Function HandleEvent([Object] $sender, [RoutedEventArgs] $e) {
    # Get the data context of the sender. This is the root element of the property path.
    [Object] $dataContext = ($sender -as [FrameworkElement]).DataContext
    # Fetch the path worker of our path.
    [Object] $worker = [RunScriptBlockExtension]::SingleWorkerProperty.GetMethod.Invoke($this.Path, @())
    # Give the data context to the worker.
    [RunScriptBlockExtension]::AttachToRootItemMethod.Invoke($worker, @($dataContext))
    # Get the resolved ScriptBlock from the worker.
    [ScriptBlock] $scriptBlock = [RunScriptBlockExtension]::RawValueMethod.Invoke($worker, @())
    $scriptBlock.InvokeReturnAsIs($dataContext, $sender, $e)
  }

}




# Declares attached properties for Grid.
<# Class GridEx #> {

  # Attached property that can be used to automatically create ColumnDefinitions for
  # a Grid using only a number.
  # <Grid ps:GridEx.Columns="5">...</Grid>
  Static [DependencyProperty] $ColumnsProperty = [DependencyProperty]::RegisterAttached(
    'Columns', [Int32], [GridEx], [PropertyMetadata]::new(-1, {
      Param ([DependencyObject] $object, [DependencyPropertyChangedEventArgs] $e)
      [Grid] $grid = $object -as [Grid]
      [Int32] $columns = $e.NewValue
      If ($grid -cne $null -and $columns -cge 0) {
        Write-Debug 'GridEx::ColumnsProperty: Clearing columns.'
        $grid.ColumnDefinitions.Clear()
        If ($columns -cgt 0) {
          1 .. $columns `
          | ForEach-Object {
            Write-Debug "GridEx::ColumnsProperty: Adding column $PSItem."
            $grid.ColumnDefinitions.Add((New-Object ColumnDefinition -Property @{
              Width = [GridLength]::Auto
            }))
          }
        }
      }
    })
  )

  # Attached property that can be used to automatically create RowDefinitions for
  # a Grid using only a number.
  # <Grid ps:GridEx.Rows="5">...</Grid>
  Static [DependencyProperty] $RowsProperty = [DependencyProperty]::RegisterAttached(
    'Rows', [Int32], [GridEx], [PropertyMetadata]::new(-1, {
      Param ([DependencyObject] $object, [DependencyPropertyChangedEventArgs] $e)
      [Grid] $grid = $object -as [Grid]
      [Int32] $rows = $e.NewValue
      If ($grid -cne $null -and $rows -cge 0) {
        Write-Debug 'GridEx::RowsProperty: Clearing rows.'
        $grid.RowDefinitions.Clear()
        If ($rows -cgt 0) {
          1 .. $rows `
          | ForEach-Object {
            Write-Debug "GridEx::RowsProperty: Adding row $PSItem."
            $grid.RowDefinitions.Add((New-Object RowDefinition -Property @{
              Height = [GridLength]::Auto
            }))
          }
        }
      }
    })
  )

  <# Static [Void] #> Function SetColumns([DependencyObject] $object, [Int32] $columns) {
    $object.SetValue([GridEx]::ColumnsProperty, $columns)
  }

  <# Static [Void] #> Function SetRows([DependencyObject] $object, [Int32] $rows) {
    $object.SetValue([GridEx]::RowsProperty, $rows)
  }

}




[Flags()]
Enum MouseState {
  NoButtonDown
  LeftButtonDown
  RightButtonDown
  BothButtonsDown
  ClickAllowed
}




Enum FieldMark {
  NoMark
  MineMark
  QuestionMark
  MaximumMark
}