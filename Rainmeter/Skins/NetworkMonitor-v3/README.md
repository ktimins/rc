# Network Monitor v2 - Illustro Style

A network ping monitor redesigned to match the illustro theme aesthetic with clean bars and compact layout.

## Features

- **Real-time Monitoring**: Pings target IP every 10 seconds (configurable)
- **Illustro Styling**: Matches the classic Rainmeter illustro theme
- **Visual History**: 6 stacked horizontal bars showing last 60 seconds of connectivity
- **Compact Layout**: Clean label:value:bar pattern for all metrics
- **Status Indicators**:
  - Golden bars for successful connections
  - Red status bar when connection is down
  - Dim bars for failed ping history
- **Metrics Displayed**:
  - Current status (UP/DOWN)
  - Ping latency in milliseconds
  - Uptime percentage
  - Visual history of last 6 pings

## Installation

1. **Copy the skin folder** to your Rainmeter Skins directory:
   - Default location: `C:\Users\YourUsername\Documents\Rainmeter\Skins\`
   - Copy the entire `NetworkMonitor-v2` folder here

2. **Refresh Rainmeter**:
   - Right-click Rainmeter system tray icon
   - Click "Refresh all"

3. **Load the skin**:
   - Right-click Rainmeter system tray icon
   - Navigate to `Skins → NetworkMonitor-v2 → NetworkMonitor-v2.ini`
   - Click to activate

## Configuration

Edit the `NetworkMonitor-v2.ini` file and modify the variables in the `[Variables]` section:

### Target Configuration

```ini
TargetIP=8.8.8.8          ; IP address to monitor (default: Google DNS)
PingInterval=10           ; Seconds between pings (default: 10)
Timeout=5000              ; Ping timeout in milliseconds (default: 5000)
```

### Visual Configuration

```ini
fontName=Trebuchet MS              ; Font family
textSize=8                         ; Text size
colorBar=235,170,0,255            ; Color for bars (golden/amber)
colorBarDim=100,100,100,100       ; Color for failed ping bars (gray)
colorText=255,255,255,205         ; Text color (white with transparency)
```

### Alert Configuration

```ini
AlertThreshold=3          ; Number of consecutive failures before changing status bar to red
```

## Design Philosophy

This version follows the illustro theme design language:

- **Background**: Uses illustro's signature background image with proper margins
- **Color Scheme**: Golden/amber accent color (`235,170,0`) consistent with illustro
- **Typography**: Trebuchet MS font with shadow effects for depth
- **Layout**: Centered title, left-aligned labels, right-aligned values, thin bars
- **Spacing**: Compact vertical spacing matching illustro's information density
- **History Visualization**: 6 stacked horizontal bars (5px apart) instead of color boxes

## Visual Elements

### Status Bar
- **Golden**: Connection is UP
- **Red**: Connection is DOWN
- Shows full width when active

### Latency Bar
- Visualizes ping response time (0-500ms range)
- Golden color, proportional to latency

### Uptime Bar
- Shows percentage of successful pings since skin loaded
- Golden color, proportional to uptime percentage

### History Bars (6 bars, oldest to newest, top to bottom)
- **Bar 1**: 60 seconds ago
- **Bar 2**: 50 seconds ago
- **Bar 3**: 40 seconds ago
- **Bar 4**: 30 seconds ago
- **Bar 5**: 20 seconds ago
- **Bar 6**: 10 seconds ago (most recent)

**Bar Colors:**
- **Golden**: Successful ping
- **Dim gray**: Failed ping

## Common Configurations

### Monitor Your Router
```ini
TargetIP=192.168.1.1
```

### Monitor a Local Server
```ini
TargetIP=192.168.1.100
PingInterval=5
```

### Monitor External Service
```ini
TargetIP=1.1.1.1          ; Cloudflare DNS
PingInterval=15
```

## Differences from v1

**NetworkMonitor v1** (functional/modern):
- Large color-coded boxes for history
- Dark semi-transparent background
- Segoe UI font
- Alert indicator text
- More spacing and larger size

**NetworkMonitor v2** (illustro/compact):
- Thin stacked bars for history
- Illustro background image
- Trebuchet MS font with shadows
- Status indicated by bar color
- Compact layout matching illustro suite

Both versions offer the same functionality - choose based on your aesthetic preference.

## Troubleshooting

### Skin shows "DOWN" constantly
- Check that the target IP is correct and reachable
- Verify your firewall isn't blocking ICMP (ping) packets
- Try pinging the IP from command prompt: `ping 8.8.8.8`

### History bars not updating
- Ensure Lua script is in the `@Resources` folder
- Check Rainmeter logs: Manage → About → Log tab
- Verify Ping plugin is installed (bundled with Rainmeter)

### Background not showing
- Verify illustro skins are installed (comes default with Rainmeter)
- Check background path in `[Rainmeter]` section
- Default path: `C:\Program Files\Rainmeter\Defaults\Skins\illustro\@Resources\Background.png`

### Colors don't match your illustro theme
- Edit `colorBar` variable to match your preferred accent color
- Common illustro colors:
  - Orange: `235,170,0,255`
  - Blue: `0,150,255,255`
  - Green: `0,200,100,255`

## Technical Details

### Files Structure
```
NetworkMonitor-v2/
├── NetworkMonitor-v2.ini           # Main skin file
├── @Resources/
│   └── HistoryManager.lua         # History tracking script
└── README.md                      # This file
```

### How It Works

1. **Ping Measure**: Uses Rainmeter's Ping plugin to send ICMP echo requests
2. **History Tracking**: Lua script maintains rotating buffer of last 6 results
3. **Visual Updates**: Bars update color via Lua script based on ping success/failure
4. **Statistics**: Calc measures track success rate and uptime percentage
5. **Styling**: Centralized style sections ensure consistent appearance

### Performance

- **Update Frequency**: 1000ms (skin updates every second)
- **Ping Frequency**: Configurable (default 10 seconds)
- **Memory Usage**: ~2-5 MB typical
- **CPU Usage**: Negligible (<0.1% on modern systems)

## Customization Ideas

### Adjust History Bar Spacing
Modify the Y position of each `meterHistory` bar (default: 5px apart)

### Change Bar Thickness
Modify the `H` parameter in history bars (default: `H=1`)

### Add More History Bars
1. Add more variables (`History7`, `History8`, etc.)
2. Create more meter sections (`[meterHistory7]`, etc.)
3. Update Lua script array size and loops
4. Adjust Y positions

### Use Different Background
Replace the Background path in `[Rainmeter]` section with your own image

## License

Creative Commons Attribution-Non-Commercial-Share Alike 3.0

## Version History

- **2.0** (2025): Illustro-styled redesign
  - Stacked bar history visualization
  - Illustro theme integration
  - Compact layout
  - Trebuchet MS typography
  - Golden/amber color scheme

## Credits

Created by KTimins, inspired by the classic Rainmeter illustro theme suite.
