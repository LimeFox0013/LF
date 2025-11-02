# LF Classes Reference

AI development context for all GDScript classes in the LF utility library.

## Components

### Core Components

- **LFComponents** - Helper class for dynamically creating and initializing LF components from scenes
- **LFControl** - Extended Control node with global registry system for accessing controls by ID, plus helper methods for calculating center positions in viewport and local coordinates
- **LFLayoutControl** - Control node that doesn't block mouse/focus interactions (click-through), useful for layout-only UI elements that should not interfere with underlying controls
- **LFControl2D** - Viewport anchor for 2D nodes, synchronizes Node2D positions with Control layout system

### Table System

- **LFTable** - Main table component that manages header, body, and footer sections with configurable column definitions and row data
- **LFTableHeader** - Table header section component
- **LFTableBody** - Table body section component containing rows
- **LFTableFooter** - Table footer section component
- **LFTableRow** - Horizontal container for table cells that binds data and builds cells based on table definition
- **LFTableCell** - Individual table cell container with configurable content
- **LFTableSection** - Base MarginContainer class for table sections (header, body, footer)
- **LFTableColDef** - Resource defining table column configuration with name property
- **LFTableDef** (utils) - Resource for basic table configuration (header/footer visibility toggles)
- **LFTableDef** (components) - Control node that collects and manages LFTableCellDef children for table structure
- **LFTableCellDef** - Control defining individual cell properties including size constraints (maxX, maxY)

## Utilities

### Core Utilities

- **LFUtils** - General purpose utilities including timer creation, timeout helpers, array/object merging, deep equality comparison, file I/O (text and JSON), and directory management

### Animation & Timing

- **LFAnimate** - Animation utilities for creating tweens on Control node properties with configurable duration and easing
- **LFAwait** - Async utilities providing `all()` to await multiple callables, `any()` to await first completion, and `nextTick` for process frame waiting
- **LFDebounce** - Function debouncing utility that delays callback execution until after calls have stopped
- **LFThrottle** - Function throttling utility that limits callback execution rate with optional leading/trailing execution

### Events & Communication

- **LFEventBus** - Global singleton event bus for application-wide pub/sub messaging pattern with emit, on, once, and off methods
- **LFEventEmitter** - Instance-based event emitter for custom events with on/once/off/emit, supports async event handlers

### Object Management

- **LFFactory** - Object pooling factory system for managing reusable entities with create/return lifecycle and pool management
- **LFFactoryInstruction** - Resource defining factory creation instructions with key and callable creator

### File System

- **LFFileObserver** - Reactive file observer that watches a file and provides data property with optional transform functions for reading/writing
- **LFJsonFileObserver** - Specialized file observer for JSON files with automatic stringify/parse transformations

### Network & OS

- **LFHTTP** - Full-featured HTTP client with automatic redirect following, TLS support, timeout handling, JSON response parsing, and free TCP port finder
- **LFOS** - Operating system and architecture detection utilities (Windows, Linux, macOS, Android, iOS, Web), CPU architecture detection (x86_64, ARM64, ARM32, WASM32), and backend selection for hardware acceleration (Metal, CUDA, Vulkan, CPU)
- **LFShell** - Cross-platform shell command execution utility (currently commented out)

### State Machine

- **LFSM** - Finite state machine implementation with transition support, hooks, and signals for state changes
- **LFSMCfg** - State machine configuration resource defining initial state, transitions, and hooks
- **LFSMTransition** - Resource defining a state transition with name, source states (from), and destination state (to)
- **LFSMHook** - Base class for state machine lifecycle hooks
- **LFSMTransitionGuard** - Hook that validates whether a transition can occur (conditional transitions)
- **LFSMOnEnterState** - Hook executed when entering specific states
- **LFSMOnLeaveState** - Hook executed when leaving specific states
- **LFSMOnAfterTransition** - Hook executed after completing specific transitions

### Threading

- **LFThread** - Cooperative thread management with cancellation support, polling-based completion checking, signals for lifecycle events, and thread status tracking

### Miscellaneous

- **LFSpine** - Placeholder class for Spine animation integration (empty implementation)
- **LFUuid** - UUID v4 generator (RFC 4122 compliant) producing lowercase hyphenated strings with optional prefix support
- **LFZip** - Static facade for zip file operations with simple async unpack functionality
- **ZipUnpacker** - Background worker for unpacking zip archives with progress reporting and cancellation support

---

## Usage Notes

- Most utilities are static classes providing immediate functionality without instantiation
- Event system supports both global (LFEventBus) and instance-based (LFEventEmitter) patterns
- State machine supports async operations in hooks and transitions
- File observers provide reactive data binding for file-based storage
- Threading utilities support cooperative cancellation and non-blocking status checks
- HTTP client handles redirects and timeouts automatically
