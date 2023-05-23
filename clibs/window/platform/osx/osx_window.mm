#include <Cocoa/Cocoa.h>
#include "../../window.h"
#include "../../virtual_keys.h"

static uint8_t keyboard_state(NSEvent* event) {
    int flags = [event modifierFlags];
	return 0
		| ((0 != (flags & NSEventModifierFlagShift  ))  ? (uint8_t)(1 << KB_SHIFT)    : 0)
		| ((0 != (flags & NSEventModifierFlagOption ))  ? (uint8_t)(1 << KB_ALT)      : 0)
		| ((0 != (flags & NSEventModifierFlagControl))  ? (uint8_t)(1 << KB_CTRL)     : 0)
		| ((0 != (flags & NSEventModifierFlagCommand))  ? (uint8_t)(1 << KB_SYS)      : 0)
		| ((0 != (flags & NSEventModifierFlagCapsLock)) ? (uint8_t)(1 << KB_CAPSLOCK) : 0)
		;
}

static int keyboard_key(NSEvent* event) {
	NSString* key = [event charactersIgnoringModifiers];
	if ([key length] == 0) {
		return 0;
	}
	int code = [key characterAtIndex:0];
	switch (code) {
    case 0x08: case 0x7F:          return VK_BACK;
    case 0x09:                     return VK_TAB;
    case 0x0D: case 0x03:          return VK_RETURN;
    case 0x1B:                     return VK_ESCAPE;
    case ' ':                      return VK_SPACE;
    case ';':  case ':':           return VK_OEM_1;
    case '=':  case '+':           return VK_OEM_PLUS;
    case ',':  case '<':           return VK_OEM_COMMA;
    case '-':  case '_':           return VK_OEM_MINUS;
    case '.':  case '>':           return VK_OEM_PERIOD;
    case '/':  case '?':           return VK_OEM_2;
    case '`':  case '~':           return VK_OEM_3;
    case '[':  case '{':           return VK_OEM_4;
    case '\\': case '|':           return VK_OEM_5;
    case ']':  case '}':           return VK_OEM_6;
    case '\'': case '"':           return VK_OEM_7;
    case '0': case ')':            return VK_0;
    case '1': case '!':            return VK_1;
    case '2': case '@':            return VK_2;
    case '3': case '#':            return VK_3;
    case '4': case '$':            return VK_4;
    case '5': case '%':            return VK_5;
    case '6': case '^':            return VK_6;
    case '7': case '&':            return VK_7;
    case '8': case '*':            return VK_8;
    case '9': case '(':            return VK_9;
    case 'a': case 'A':            return VK_A;
    case 'b': case 'B':            return VK_B;
    case 'c': case 'C':            return VK_C;
    case 'd': case 'D':            return VK_D;
    case 'e': case 'E':            return VK_E;
    case 'f': case 'F':            return VK_F;
    case 'g': case 'G':            return VK_G;
    case 'h': case 'H':            return VK_H;
    case 'i': case 'I':            return VK_I;
    case 'j': case 'J':            return VK_J;
    case 'k': case 'K':            return VK_K;
    case 'l': case 'L':            return VK_L;
    case 'm': case 'M':            return VK_M;
    case 'n': case 'N':            return VK_N;
    case 'o': case 'O':            return VK_O;
    case 'p': case 'P':            return VK_P;
    case 'q': case 'Q':            return VK_Q;
    case 'r': case 'R':            return VK_R;
    case 's': case 'S':            return VK_S;
    case 't': case 'T':            return VK_T;
    case 'u': case 'U':            return VK_U;
    case 'v': case 'V':            return VK_V;
    case 'w': case 'W':            return VK_W;
    case 'x': case 'X':            return VK_X;
    case 'y': case 'Y':            return VK_Y;
    case 'z': case 'Z':            return VK_Z;
	case NSF1FunctionKey:          return VK_F1;
	case NSF2FunctionKey:          return VK_F2;
	case NSF3FunctionKey:          return VK_F3;
	case NSF4FunctionKey:          return VK_F4;
	case NSF5FunctionKey:          return VK_F5;
	case NSF6FunctionKey:          return VK_F6;
	case NSF7FunctionKey:          return VK_F7;
	case NSF8FunctionKey:          return VK_F8;
	case NSF9FunctionKey:          return VK_F9;
	case NSF10FunctionKey:         return VK_F10;
    case NSF11FunctionKey:         return VK_F11;
    case NSF12FunctionKey:         return VK_F12;
    case NSF13FunctionKey:         return VK_F13;
    case NSF14FunctionKey:         return VK_F14;
    case NSF15FunctionKey:         return VK_F15;
    case NSF16FunctionKey:         return VK_F16;
    case NSF17FunctionKey:         return VK_F17;
    case NSF18FunctionKey:         return VK_F18;
    case NSF19FunctionKey:         return VK_F19;
    case NSF20FunctionKey:         return VK_F20;
    case NSF21FunctionKey:         return VK_F21;
    case NSF22FunctionKey:         return VK_F22;
    case NSF23FunctionKey:         return VK_F23;
    case NSF24FunctionKey:         return VK_F24;
	case NSLeftArrowFunctionKey:   return VK_LEFT;
	case NSRightArrowFunctionKey:  return VK_RIGHT;
	case NSUpArrowFunctionKey:     return VK_UP;
	case NSDownArrowFunctionKey:   return VK_DOWN;
	case NSPageUpFunctionKey:      return VK_PRIOR;
	case NSPageDownFunctionKey:    return VK_NEXT;
	case NSHomeFunctionKey:        return VK_HOME;
	case NSEndFunctionKey:         return VK_END;
	case NSPrintScreenFunctionKey: return VK_SNAPSHOT;
    case NSScrollLockFunctionKey:  return VK_SCROLL;
    case NSPauseFunctionKey:       return VK_PAUSE;
    case NSSelectFunctionKey:      return VK_SELECT;
    case NSDeleteFunctionKey:      return VK_DELETE;
    case NSPrintFunctionKey:       return VK_PRINT;
    case NSExecuteFunctionKey:     return VK_EXECUTE;
    case NSInsertFunctionKey:      return VK_INSERT;
    case NSHelpFunctionKey:        return VK_HELP;
	}
	return 0;
}

static int32_t clamp(int32_t v, int32_t min, int32_t max) {
    if (v < min) {
        return min;
    }
    if (v > max) {
        return max;
    }
    return v;
}

@interface AppDelegate : NSObject <NSApplicationDelegate> {
    bool terminated;
}
- (id)init;
- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender;
- (bool)applicationHasTerminated;
@end

@implementation AppDelegate
- (id)init {
    self = [super init];
    if (nil == self) {
        return nil;
    }
    self->terminated = false;
    return self;
}
- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender {
	(void)sender;
	self->terminated = true;
	return NSTerminateCancel;
}
- (bool)applicationHasTerminated {
	return self->terminated;
}
@end

@interface WindowDelegate : NSObject<NSWindowDelegate> {
    uint32_t m_count;
    NSWindow* m_window;
    struct ant_window_callback* m_cb;
}
- (id)init;
- (void)getMouseX:(int32_t*)outx getMouseY:(int32_t*)outy;
- (void)windowCreated:(NSWindow*)window initCallback:(struct ant_window_callback*)callback ;
- (void)windowWillClose:(NSNotification*)notification;
- (BOOL)windowShouldClose:(NSWindow*)window;
@end

@implementation WindowDelegate
- (id)init {
	self = [super init];
	if (nil == self) {
		return nil;
	}
	self->m_count = 0;
	return self;
}
- (void)getMouseX:(int32_t*)outx getMouseY:(int32_t*)outy {
	NSRect  originalFrame = [m_window frame];
	NSPoint location      = [m_window mouseLocationOutsideOfEventStream];
	NSRect  adjustFrame   = [m_window contentRectForFrameRect: originalFrame];
	int32_t x = location.x;
	int32_t y = (int32_t)adjustFrame.size.height - (int32_t)location.y;
	*outx = clamp(x, 0, (int32_t)adjustFrame.size.width);
	*outy = clamp(y, 0, (int32_t)adjustFrame.size.height);
}
- (void)windowCreated:(NSWindow*)window initCallback:(struct ant_window_callback*)callback {
	assert(window);
    m_window = window;
    m_cb = callback;
	[window setDelegate:self];
	assert(self->m_count < ~0u);
	self->m_count += 1;
}
- (void)windowWillClose:(NSNotification*)notification {
	(void)notification;
    window_message_exit(m_cb);
}
- (BOOL)windowShouldClose:(NSWindow*)window {
	assert(window);
	assert(self->m_count);
	self->m_count -= 1;
	if (self->m_count == 0) {
		[NSApp terminate:self];
	}
	return YES;
}
@end

WindowDelegate* g_wd = nil;
int32_t g_mx = 0;
int32_t g_my = 0;

int window_init(struct ant_window_callback* cb) {
	int w = 1334;
	int h = 750;
    NSRect rc = NSMakeRect(0, 0, w, h);
	NSUInteger uiStyle = 0
		| NSWindowStyleMaskTitled
		| NSWindowStyleMaskClosable
		| NSWindowStyleMaskMiniaturizable
		;
    NSWindow* win = [[NSWindow alloc]
        initWithContentRect:rc
        styleMask:uiStyle
        backing:NSBackingStoreBuffered defer:NO
    ];

    [win center];
    [win makeKeyAndOrderFront:win];
    [win makeMainWindow];

    g_wd = [WindowDelegate new];
    [g_wd windowCreated:win initCallback:cb];

    window_message_init(cb, win, 0, w, h);
    return 0;
}

static NSEvent* peek_event() {
	return [NSApp
		nextEventMatchingMask:NSEventMaskAny
		untilDate:[NSDate distantPast] // do not wait for event
		inMode:NSDefaultRunLoopMode
		dequeue:YES
	];
}

static bool dispatch_event(struct ant_window_callback* cb, NSEvent* event) {
	if (!event) {
	    return false;
	}
	NSEventType eventType = [event type];

	switch (eventType) {
	case NSEventTypeMouseMoved:
	case NSEventTypeLeftMouseDragged:
	case NSEventTypeRightMouseDragged:
	case NSEventTypeOtherMouseDragged: {
		[g_wd getMouseX:&g_mx getMouseY:&g_my];
		uint8_t type = 0;
        switch (eventType) {
        case NSEventTypeMouseMoved:        type = 0; break;
        case NSEventTypeLeftMouseDragged:  type = 1; break;
        case NSEventTypeRightMouseDragged: type = 2; break;
        case NSEventTypeOtherMouseDragged: type = 3; break;
        default: break;
        }
        window_message_mouse(cb, g_mx, g_my, type, 2);
        break;
    }
	case NSEventTypeScrollWheel:
        window_message_mouse_wheel(cb, g_mx, g_my, 0.5f * [event scrollingDeltaY]);
        break;
	case NSEventTypeLeftMouseDown:
	case NSEventTypeLeftMouseUp:
        window_message_mouse(cb, g_mx, g_my, 1, (eventType == NSEventTypeLeftMouseDown) ? 1 : 3);
        break;
	case NSEventTypeRightMouseDown:
	case NSEventTypeRightMouseUp:
        window_message_mouse(cb, g_mx, g_my, 2, (eventType == NSEventTypeRightMouseDown) ? 1 : 3);
        break;
	case NSEventTypeOtherMouseDown:
	case NSEventTypeOtherMouseUp:
        window_message_mouse(cb, g_mx, g_my, 3, (eventType == NSEventTypeOtherMouseDown) ? 1 : 3);
        break;
	case NSEventTypeKeyDown:
	case NSEventTypeKeyUp:
        window_message_keyboard(cb, keyboard_key(event), keyboard_state(event), (eventType == NSEventTypeKeyDown) ? 1 : 0);
		break;
	default:
		break;
    }
	[NSApp sendEvent:event];
	[NSApp updateWindows];
	return true;
}

void window_mainloop(struct ant_window_callback* cb, int update) {
    if (!g_wd) {
        return;
    }
    [NSApplication sharedApplication];
    id dg = [AppDelegate new];
    [NSApp setDelegate:dg];
    [NSApp setActivationPolicy:NSApplicationActivationPolicyRegular];
    [NSApp activateIgnoringOtherApps:YES];
    [NSApp finishLaunching];
    while (![dg applicationHasTerminated]) {
        if (update) {
            cb->update(cb);
        }
        @autoreleasepool {
            while (dispatch_event(cb, peek_event())) { }
        }
    }
}