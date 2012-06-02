#!/usr/bin/env python3
# -*- coding: utf-8 -*-
#
# pySFML2 - Cython SFML Wrapper for Python
# Copyright 2012, Jonathan De Wachter <dewachter.jonathan@gmail.com>
#
# This software is released under the GPLv3 license.
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

cimport cython
from cython.operator cimport dereference as deref, preincrement as inc

from libcpp.vector cimport vector

from sfml.system.position import Position
from sfml.system.size import Size
from sfml.system.rectangle import Rectangle

from dsystem cimport Int8, Int16, Int32, Int64
from dsystem cimport Uint8, Uint16, Uint32, Uint64

from dsystem cimport const_Uint8_ptr

cimport dsystem, dwindow, dgraphics

string_type = [bytes, unicode, str]
numeric_type = [int, long, float, long]

########################################################################
#                           System Module                              #
########################################################################

class SFMLException(Exception):
	def __init__(self, value=None):
		self.value = value
		
	def __str__(self):
		return repr(self.value)

cdef class Time:
	ZERO = wrap_time(<dsystem.Time*>&dsystem.time.Zero)

	cdef dsystem.Time *p_this

	def __init__(self):
		self.p_this = new dsystem.Time()

	def __dealloc__(self):
		del self.p_this

	def __repr__(self):
		return "sf.Time({0}s, {1}ms, {2}µs)".format(self.seconds, self.milliseconds, self.microseconds)
		
	def __str__(self):
		return "{0} milliseconds".format(self.milliseconds)

	def __richcmp__(Time x, Time y, int op):
		if op == 0:   return x.p_this[0] <  y.p_this[0]
		elif op == 2: return x.p_this[0] == y.p_this[0]
		elif op == 4: return x.p_this[0] >  y.p_this[0]
		elif op == 1: return x.p_this[0] <= y.p_this[0]
		elif op == 3: return x.p_this[0] != y.p_this[0]
		elif op == 5: return x.p_this[0] >= y.p_this[0]

	def __add__(Time x, Time y):
		cdef dsystem.Time* p = new dsystem.Time()
		p[0] = x.p_this[0] + y.p_this[0]
		return wrap_time(p)
		
	def __sub__(Time x, Time y):
		cdef dsystem.Time* p = new dsystem.Time()
		p[0] = x.p_this[0] - y.p_this[0]
		return wrap_time(p)
		
	def __iadd__(self, Time x):
		self.p_this[0] = self.p_this[0] + x.p_this[0]
		return self

	def __isub__(self, Time x):
		self.p_this[0] = self.p_this[0] - x.p_this[0]
		return self

	property seconds:
		def __get__(self):
			return self.p_this.asSeconds()

		def __set__(self, float seconds):
			self.p_this[0] = dsystem.seconds(seconds)

	property milliseconds:
		def __get__(self):
			return self.p_this.asMilliseconds()

		def __set__(self, Int32 milliseconds):
			self.p_this[0] = dsystem.milliseconds(milliseconds)

	property microseconds:
		def __get__(self):
			return self.p_this.asMicroseconds()

		def __set__(self, Int64 microseconds):
			self.p_this[0] = dsystem.microseconds(microseconds)

	def reset(self):
		self.milliseconds = 0

	def copy(self):
		cdef dsystem.Time* p = new dsystem.Time()
		p[0] = self.p_this[0]
		return wrap_time(p)

 
def sleep(Time duration):
	dsystem.sleep(duration.p_this[0])


cdef class Clock:
	cdef dsystem.Clock *p_this

	def __cinit__(self):
		self.p_this = new dsystem.Clock()

	def __dealloc__(self):
		del self.p_this

	def __repr__(self):
		return "sf.Clock({0})".format(self.elapsed_time)
		
	def __str__(self):
		return "{0}".format(self.elapsed_time)
		
	property elapsed_time:
		def __get__(self):
			cdef dsystem.Time* p = new dsystem.Time()
			p[0] = self.p_this.getElapsedTime()
			return wrap_time(p)

	def restart(self):
		cdef dsystem.Time* p = new dsystem.Time()
		p[0] = self.p_this.restart()
		return wrap_time(p)

def seconds(float amount):
	cdef dsystem.Time* p = new dsystem.Time()
	p[0] = dsystem.seconds(amount)
	return wrap_time(p)
	
def milliseconds(Int32 amount):
	cdef dsystem.Time* p = new dsystem.Time()
	p[0] = dsystem.milliseconds(amount)
	return wrap_time(p)
	
def microseconds(Int64 amount):
	cdef dsystem.Time* p = new dsystem.Time()
	p[0] = dsystem.microseconds(amount)
	return wrap_time(p)


cdef Time wrap_time(dsystem.Time* p):
	cdef Time r = Time.__new__(Time)
	r.p_this = p
	return r

cdef dsystem.FloatRect rectangle_to_floatrect(rectangle):
	l, t, w, h = rectangle
	return dsystem.FloatRect(l, t, w, h)
	
cdef dsystem.IntRect rectangle_to_intrect(rectangle):
	l, t, w, h = rectangle
	return dsystem.IntRect(l, t, w, h)

cdef dsystem.Vector2i position_to_vector2i(position):
	x, y = position
	return dsystem.Vector2i(x, y)
	
cdef dsystem.Vector2f position_to_vector2f(position):
	x, y = position
	return dsystem.Vector2f(x, y)

cdef dsystem.Vector2u size_to_vector2u(size):
	w, h = size
	return dsystem.Vector2u(w, h)
	
cdef dsystem.Vector2f size_to_vector2f(size):
	w, h = size
	return dsystem.Vector2f(w, h)

cdef object intrect_to_rectangle(dsystem.IntRect* intrect):
	return Rectangle((intrect.left, intrect.top), (intrect.width, intrect.height))

cdef object floatrect_to_rectangle(dsystem.FloatRect* floatrect):
	return Rectangle((floatrect.left, floatrect.top), (floatrect.width, floatrect.height))


########################################################################
#                           Window Module                              #
########################################################################

cdef class Style:
	NONE = dwindow.style.None
	TITLEBAR = dwindow.style.Titlebar
	RESIZE = dwindow.style.Resize
	CLOSE = dwindow.style.Close
	FULLSCREEN = dwindow.style.Fullscreen
	DEFAULT = dwindow.style.Default


cdef class Event:
	CLOSED = dwindow.event.Closed
	RESIZED = dwindow.event.Resized
	LOST_FOCUS = dwindow.event.LostFocus
	GAINED_FOCUS = dwindow.event.GainedFocus
	TEXT_ENTERED = dwindow.event.TextEntered
	KEY_PRESSED = dwindow.event.KeyPressed
	KEY_RELEASED = dwindow.event.KeyReleased
	MOUSE_WHEEL_MOVED = dwindow.event.MouseWheelMoved
	MOUSE_BUTTON_PRESSED = dwindow.event.MouseButtonPressed
	MOUSE_BUTTON_RELEASED = dwindow.event.MouseButtonReleased
	MOUSE_MOVED = dwindow.event.MouseMoved
	MOUSE_ENTERED = dwindow.event.MouseEntered
	MOUSE_LEFT = dwindow.event.MouseLeft
	JOYSTICK_BUTTON_PRESSED = dwindow.event.JoystickButtonPressed
	JOYSTICK_BUTTON_RELEASED = dwindow.event.JoystickButtonReleased
	JOYSTICK_MOVED = dwindow.event.JoystickMoved
	JOYSTICK_CONNECTED = dwindow.event.JoystickConnected
	JOYSTICK_DISCONNECTED = dwindow.event.JoystickDisconnected
	COUNT = dwindow.event.Count

	cdef dwindow.Event *p_this

	def __init__(self):
		self.p_this = new dwindow.Event()

	def __dealloc__(self):
		del self.p_this

	def __repr__(self):
		return ("sf.Event({0})".format(self))

	def __str__(self):
		if self.type == Event.CLOSED:
			return "The window requested to be closed"
		elif self.type == Event.LOST_FOCUS:
			return "The window lost the focus"
		elif self.type == Event.GAINED_FOCUS:
			return "The window gained the focus"
		elif self.type == Event.MOUSE_ENTERED:
			return "The mouse cursor entered the area of the window"
		elif self.type == Event.MOUSE_LEFT:
			return "The mouse cursor left the area of the window"

	property type:
		def __get__(self):
			return self.p_this.type
			
		def __set__(self, dwindow.event.EventType type):
			self.p_this.type = type


cdef class SizeEvent(Event):
	def __str__(self):
		return "The window was resized"
		
	property width:
		def __get__(self):
			return self.p_this.size.width
			
		def __set__(self, unsigned int width):
			self.p_this.size.width = width
		
	property height:
		def __get__(self):
			return self.p_this.size.height
			
		def __set__(self, unsigned int height):
			self.p_this.size.height = height
		
	property size:
		def __get__(self):
			return Size(self.width, self.height)
			
		def __set__(self, size):
			self.width, self.height = size


cdef class KeyEvent(Event):
	def __str__(self):
		if self.type == Event.KEY_PRESSED:
			return "A key was pressed"
		elif self.type == Event.KEY_RELEASED:
			return "A key was released"
		
	property code:
		def __get__(self):
			return self.p_this.key.code
			
		def __set__(self, dwindow.keyboard.Key code):
			self.p_this.key.code = code
		
	property alt:
		def __get__(self):
			return self.p_this.key.alt
			
		def __set__(self, bint alt):
			self.p_this.key.alt = alt
			
	property control:
		def __get__(self):
			return self.p_this.key.control
			
		def __set__(self, bint control):
			self.p_this.key.control = control
			
	property shift:
		def __get__(self):
			return self.p_this.key.shift
			
		def __set__(self, bint shift):
			self.p_this.key.shift = shift
			
	property system:
		def __get__(self):
			return self.p_this.key.system
			
		def __set__(self, bint system):
			self.p_this.key.system = system


cdef class TextEvent(Event):
	def __str__(self):
		return "A character was entered"
		
	property unicode:
		def __get__(self):
			return self.p_this.text.unicode
			
		def __set__(self, Uint32 unicode):
			self.p_this.text.unicode = unicode


cdef class MouseMoveEvent(Event):
	def __str__(self):
		return "The mouse cursor moved"
		
	property x:
		def __get__(self):
			return self.p_this.mouseMove.x
			
		def __set__(self, int x):
			self.p_this.mouseMove.x = x
		
	property y:
		def __get__(self):
			return self.p_this.mouseMove.y
			
		def __set__(self, int y):
			self.p_this.mouseMove.y = y
		
	property position:
		def __get__(self):
			return Position(self.x, self.y)
			
		def __set__(self, position):
			self.x, self.y = position


cdef class MouseButtonEvent(Event):
	def __str__(self):
		if self.type == Event.MOUSE_BUTTON_PRESSED:
			return "A mouse button was pressed"
		elif self.type == Event.MOUSE_BUTTON_RELEASED:
			return "A mouse button was released"

	property button:
		def __get__(self):
			return self.p_this.mouseButton.button

		def __set__(self, dwindow.mouse.Button button):
			self.p_this.mouseButton.button = button

	property x:
		def __get__(self):
			return self.p_this.mouseButton.x

		def __set__(self, int x):
			self.p_this.mouseButton.x = x

	property y:
		def __get__(self):
			return self.p_this.mouseButton.y

		def __set__(self, int y):
			self.p_this.mouseButton.y = y

	property position:
		def __get__(self):
			return Position(self.x, self.y)

		def __set__(self, position):
			self.x, self.y = position


cdef class MouseWheelEvent(Event):
	def __str__(self):
		return "The mouse wheel was scrolled"

	property delta:
		def __get__(self):
			return self.p_this.mouseWheel.delta
			
		def __set__(self, int delta):
			self.p_this.mouseWheel.delta = delta

	property x:
		def __get__(self):
			return self.p_this.mouseWheel.x
			
		def __set__(self, int x):
			self.p_this.mouseWheel.x = x

	property y:
		def __get__(self):
			return self.p_this.mouseWheel.y

		def __set__(self, int y):
			self.p_this.mouseWheel.y = y

	property position:
		def __get__(self):
			return Position(self.x, self.y)
			
		def __set__(self, position):
			self.x, self.y = position


cdef class JoystickMoveEvent(Event):
	def __str__(self):
		return "The joystick moved along an axis"
		
	property joystick_id:
		def __get__(self):
			return self.p_this.joystickMove.joystickId
			
		def __set__(self, unsigned int joystick_id):
			self.p_this.joystickMove.joystickId = joystick_id
		
	property axis:
		def __get__(self):
			return self.p_this.joystickMove.axis
			
		def __set__(self, dwindow.joystick.Axis axis):
			self.p_this.joystickMove.axis = axis
		
	property position:
		def __get__(self):
			return self.p_this.joystickMove.position
			
		def __set__(self, float position):
			self.p_this.joystickMove.position = position

	property x:
		def __get__(self): pass
		def __set__(self, x): pass
		
	property y:
		def __get__(self): pass
		def __set__(self, y): pass
		
cdef class JoystickButtonEvent(Event):
	def __str__(self):
		if self.type == Event.JOYSTICK_BUTTON_PRESSED:
			return "A joystick button was pressed"
		elif self.type == Event.JOYSTICK_BUTTON_RELEASED:
			return "A joystick button was released"
		
	property joystick_id:
		def __get__(self):
			return self.p_this.joystickButton.joystickId
			
		def __set__(self, unsigned int joystick_id):
			self.p_this.joystickButton.joystickId = joystick_id
			
	property button:
		def __get__(self):
			return self.p_this.joystickButton.button
			
		def __set__(self, unsigned int button):
			self.p_this.joystickButton.button = button
			

cdef class JoystickConnectEvent(Event):
	def __str__(self):
		if self.type == Event.JOYSTICK_CONNECTED:
			return "A joystick was connected"
		elif self.type == Event.JOYSTICK_DISCONNECTED:
			return "A joystick was disconnected"
		
	property joystick_id:
		def __get__(self):
			return self.p_this.joystickConnect.joystickId
			
		def __set__(self, unsigned int joystick_id):
			self.p_this.joystickConnect.joystickId = joystick_id


cdef class VideoMode:
	cdef dwindow.VideoMode *p_this
	cdef bint delete_this

	def __init__(self, unsigned int width, unsigned int height, unsigned int bpp=32):
		self.p_this = new dwindow.VideoMode(width, height, bpp)
		self.delete_this = True
		
	def __dealloc__(self):
		if self.delete_this: del self.p_this

	def __repr__(self):
		return ("VideoMode({0})".format(self))

	def __str__(self):
		return "{0}x{1}x{2}".format(self.width, self.height, self.bpp)

	def __richcmp__(VideoMode x, VideoMode y, int op):
		if op == 0:   return x.p_this[0] <  y.p_this[0]
		elif op == 2: return x.p_this[0] == y.p_this[0]
		elif op == 4: return x.p_this[0] >  y.p_this[0]
		elif op == 1: return x.p_this[0] <= y.p_this[0]
		elif op == 3: return x.p_this[0] != y.p_this[0]
		elif op == 5: return x.p_this[0] >= y.p_this[0]

	def __iter__(self):
		return iter((self.size, self.bpp))
		
	property width:
		def __get__(self):
			return self.p_this.width
			
		def __set__(self, unsigned int width):
			self.p_this.width = width
		
	property height:
		def __get__(self):
			return self.p_this.height
			
		def __set__(self, unsigned int height):
			self.p_this.height = height

	property size:
		def __get__(self):
			return Size(self.p_this.width, self.p_this.height)
			
		def __set__(self, value):
			width, height = value
			self.p_this.width = width
			self.p_this.height = height

	property bpp:
		def __get__(self):
			return self.p_this.bitsPerPixel

		def __set__(self, unsigned int bpp):
			self.p_this.bitsPerPixel = bpp

	@classmethod
	def get_desktop_mode(cls):
		cdef dwindow.VideoMode *p = new dwindow.VideoMode()
		p[0] = dwindow.videomode.getDesktopMode()
		
		return wrap_videomode(p, True)
		
	@classmethod
	def get_fullscreen_modes(cls):
		cdef list modes = []
		cdef vector[dwindow.VideoMode] *v = new vector[dwindow.VideoMode]()
		v[0] = dwindow.videomode.getFullscreenModes()
		
		cdef vector[dwindow.VideoMode].iterator it = v.begin()
		cdef dwindow.VideoMode vm
		
		while it != v.end():
			vm = deref(it)
			modes.append(VideoMode(vm.width, vm.height, vm.bitsPerPixel))
			inc(it)

		return modes
		
	def is_valid(self):
		return self.p_this.isValid()


cdef class ContextSettings:
	cdef dwindow.ContextSettings *p_this

	def __init__(self, unsigned int depth=0, unsigned int stencil=0, unsigned int antialiasing=0, unsigned int major=2, unsigned int minor=0):
		self.p_this = new dwindow.ContextSettings(depth, stencil, antialiasing, major, minor)

	def __dealloc__(self):
		del self.p_this

	def __repr__(self):
		return ("ContextSettings({0})".format(self))

	def __str__(self):
		return "{0}db, {1}sb, {2}al, version {3}.{4}".format(self.depth_bits, self.stencil_bits, self.antialiasing_level, self.major_version, self.minor_version)

	def __iter__(self):
		return iter((self.depth_bits, self.stencil_bits, self.antialiasing_level, self.major_version, self.minor_version))
		
	property depth_bits:
		def __get__(self):
			return self.p_this.depthBits

		def __set__(self, unsigned int depth_bits):
			self.p_this.depthBits = depth_bits

	property stencil_bits:
		def __get__(self):
			return self.p_this.stencilBits

		def __set__(self, unsigned int stencil_bits):
			self.p_this.stencilBits = stencil_bits

	property antialiasing_level:
		def __get__(self):
			return self.p_this.antialiasingLevel

		def __set__(self, unsigned int antialiasing_level):
			self.p_this.antialiasingLevel = antialiasing_level

	property major_version:
		def __get__(self):
			return self.p_this.majorVersion

		def __set__(self, unsigned int major_version):
			self.p_this.majorVersion = major_version

	property minor_version:
		def __get__(self):
			return self.p_this.minorVersion

		def __set__(self, unsigned int minor_version):
			self.p_this.minorVersion = minor_version


cdef class Window:
	cdef dwindow.Window *p_window
	cdef bint            m_visible
	cdef bint            m_vertical_synchronization
	
	def __cinit__(self, *args, **kwargs):
		self.m_visible = True
		self.m_vertical_synchronization = False
		
	def __init__(self, VideoMode mode, title, Uint32 style=dwindow.style.Default, ContextSettings settings=None):
		cdef char* encoded_title
		
		if self.__class__ is not RenderWindow:
			encoded_title_temporary = title.encode(u"ISO-8859-1")
			encoded_title = encoded_title_temporary
			
			if self.__class__ is Window:
				if not settings: self.p_window = new dwindow.Window(mode.p_this[0], encoded_title, style)
				else: self.p_window = new dwindow.Window(mode.p_this[0], encoded_title, style, settings.p_this[0])		
				
			else:
				if not settings: self.p_window = <dwindow.Window*>new dwindow.DerivableWindow(mode.p_this[0], encoded_title, style)
				else: self.p_window = <dwindow.Window*>new dwindow.DerivableWindow(mode.p_this[0], encoded_title, style, settings.p_this[0])
				(<dwindow.DerivableWindow*>self.p_window).set_pyobj(<void*>self)		

	def __dealloc__(self):
		if self.__class__ is not RenderWindow: del self.p_window
			
	def __iter__(self):
		return self

	def __next__(self):
		cdef dwindow.Event *p = new dwindow.Event()

		if self.p_window.pollEvent(p[0]):
			return wrap_event(p)

		raise StopIteration

	def close(self):
		self.p_window.close()

	property opened:
		def __get__(self):
			return self.p_window.isOpen()

	property settings:
		def __get__(self):
			cdef dwindow.ContextSettings *p = new dwindow.ContextSettings()
			p[0] = self.p_window.getSettings()
			return wrap_contextsettings(p)

		def __set__(self, settings):
			raise NotImplemented

	property events:
		def __get__(self):
			return self

	def poll_event(self):
		cdef dwindow.Event *p = new dwindow.Event()

		if self.p_window.pollEvent(p[0]):
			return wrap_event(p)
			
	def wait_event(self):
		cdef dwindow.Event *p = new dwindow.Event()
		
		if self.p_window.waitEvent(p[0]):
			return wrap_event(p)

	property position:
		def __get__(self):
			return Position(self.p_window.getPosition().x, self.p_window.getPosition().y)

		def __set__(self, position):
			self.p_window.setPosition(position_to_vector2i(position))

	property size:
		def __get__(self):
			return Size(self.p_window.getSize().x, self.p_window.getSize().y)

		def __set__(self, size):
			self.p_window.setSize(size_to_vector2u(size))

	property title:
		def __set__(self, title):
			encoded_title = title.encode(u"ISO-8859-1")
			self.p_window.setTitle(encoded_title)

	property icon:
		def __set__(self, Pixels icon):
			self.p_window.setIcon(icon.m_width, icon.m_height, icon.p_array)

	property visible:
		def __get__(self):
			return self.m_visible
			
		def __set__(self, bint visible):
			self.p_window.setVisible(visible)
			self.m_visible = visible
			
	def show(self):
		self.visible = True
			
	def hide(self):
		self.visible = False

	property vertical_synchronization:
		def __get__(self):
			return self.m_vertical_synchronization
			
		def __set__(self, bint vertical_synchronization):
			self.p_window.setVerticalSyncEnabled(vertical_synchronization)
			self.m_vertical_synchronization = vertical_synchronization

	property mouse_cursor_visible:
		def __set__(self, bint mouse_cursor_visible):
			self.p_window.setMouseCursorVisible(mouse_cursor_visible)

	property key_repeat_enabled:
		def __set__(self, bint key_repeat_enabled):
			self.p_window.setKeyRepeatEnabled(key_repeat_enabled)

	property framerate_limit:
		def __set__(self, unsigned int framerate_limit):
			self.p_window.setFramerateLimit(framerate_limit)

	property joystick_threshold:
		def __set__(self, float joystick_threshold):
			self.p_window.setJoystickThreshold(joystick_threshold)

	property active:
		def __set__(self, bint active):
			self.p_window.setActive(active)

	def display(self):
		self.p_window.display()

	property system_handle:
		def __get__(self):
			return <unsigned long>self.p_window.getSystemHandle()

	def on_create(self): pass
	def on_resize(self): pass


cdef class Keyboard:
	A = dwindow.keyboard.A
	B = dwindow.keyboard.B
	C = dwindow.keyboard.C
	D = dwindow.keyboard.D
	E = dwindow.keyboard.E
	F = dwindow.keyboard.F
	G = dwindow.keyboard.G
	H = dwindow.keyboard.H
	I = dwindow.keyboard.I
	J = dwindow.keyboard.J
	K = dwindow.keyboard.K
	L = dwindow.keyboard.L
	M = dwindow.keyboard.M
	N = dwindow.keyboard.N
	O = dwindow.keyboard.O
	P = dwindow.keyboard.P
	Q = dwindow.keyboard.Q
	R = dwindow.keyboard.R
	S = dwindow.keyboard.S
	T = dwindow.keyboard.T
	U = dwindow.keyboard.U
	V = dwindow.keyboard.V
	W = dwindow.keyboard.W
	X = dwindow.keyboard.X
	Y = dwindow.keyboard.Y
	Z = dwindow.keyboard.Z
	NUM0 = dwindow.keyboard.Num0
	NUM1 = dwindow.keyboard.Num1
	NUM2 = dwindow.keyboard.Num2
	NUM3 = dwindow.keyboard.Num3
	NUM4 = dwindow.keyboard.Num4
	NUM5 = dwindow.keyboard.Num5
	NUM6 = dwindow.keyboard.Num6
	NUM7 = dwindow.keyboard.Num7
	NUM8 = dwindow.keyboard.Num8
	NUM9 = dwindow.keyboard.Num9
	ESCAPE = dwindow.keyboard.Escape
	L_CONTROL = dwindow.keyboard.LControl
	L_SHIFT = dwindow.keyboard.LShift
	L_ALT = dwindow.keyboard.LAlt
	L_SYSTEM = dwindow.keyboard.LSystem
	R_CONTROL = dwindow.keyboard.RControl
	R_SHIFT = dwindow.keyboard.RShift
	R_ALT = dwindow.keyboard.RAlt
	R_SYSTEM = dwindow.keyboard.RSystem
	MENU = dwindow.keyboard.Menu
	L_BRACKET = dwindow.keyboard.LBracket
	R_BRACKET = dwindow.keyboard.RBracket
	SEMI_COLON = dwindow.keyboard.SemiColon
	COMMA = dwindow.keyboard.Comma
	PERIOD = dwindow.keyboard.Period
	QUOTE = dwindow.keyboard.Quote
	SLASH = dwindow.keyboard.Slash
	BACK_SLASH = dwindow.keyboard.BackSlash
	TILDE = dwindow.keyboard.Tilde
	EQUAL = dwindow.keyboard.Equal
	DASH = dwindow.keyboard.Dash
	SPACE = dwindow.keyboard.Space
	RETURN = dwindow.keyboard.Return
	BACK = dwindow.keyboard.Back
	TAB = dwindow.keyboard.Tab
	PAGE_UP = dwindow.keyboard.PageUp
	PAGE_DOWN = dwindow.keyboard.PageDown
	END = dwindow.keyboard.End
	HOME = dwindow.keyboard.Home
	INSERT = dwindow.keyboard.Insert
	DELETE = dwindow.keyboard.Delete
	ADD = dwindow.keyboard.Add
	SUBTRACT = dwindow.keyboard.Subtract
	MULTIPLY = dwindow.keyboard.Multiply
	DIVIDE = dwindow.keyboard.Divide
	LEFT = dwindow.keyboard.Left
	RIGHT = dwindow.keyboard.Right
	UP = dwindow.keyboard.Up
	DOWN = dwindow.keyboard.Down
	NUMPAD0 = dwindow.keyboard.Numpad0
	NUMPAD1 = dwindow.keyboard.Numpad1
	NUMPAD2 = dwindow.keyboard.Numpad2
	NUMPAD3 = dwindow.keyboard.Numpad3
	NUMPAD4 = dwindow.keyboard.Numpad4
	NUMPAD5 = dwindow.keyboard.Numpad5
	NUMPAD6 = dwindow.keyboard.Numpad6
	NUMPAD7 = dwindow.keyboard.Numpad7
	NUMPAD8 = dwindow.keyboard.Numpad8
	NUMPAD9 = dwindow.keyboard.Numpad9
	F1 = dwindow.keyboard.F1
	F2 = dwindow.keyboard.F2
	F3 = dwindow.keyboard.F3
	F4 = dwindow.keyboard.F4
	F5 = dwindow.keyboard.F5
	F6 = dwindow.keyboard.F6
	F7 = dwindow.keyboard.F7
	F8 = dwindow.keyboard.F8
	F9 = dwindow.keyboard.F9
	F10 = dwindow.keyboard.F10
	F11 = dwindow.keyboard.F11
	F12 = dwindow.keyboard.F12
	F13 = dwindow.keyboard.F13
	F14 = dwindow.keyboard.F14
	F15 = dwindow.keyboard.F15
	PAUSE = dwindow.keyboard.Pause
	KEY_COUNT = dwindow.keyboard.KeyCount

	def __init__(self):
		raise NotImplementedError("This class is not meant to be instantiated!")
		
	@classmethod
	def is_key_pressed(cls, int key):
		return dwindow.keyboard.isKeyPressed(<dwindow.keyboard.Key>key)


cdef class Joystick:
	COUNT = dwindow.joystick.Count
	BUTTON_COUNT = dwindow.joystick.ButtonCount
	AXIS_COUNT = dwindow.joystick.AxisCount

	X = dwindow.joystick.X
	Y = dwindow.joystick.Y
	Z = dwindow.joystick.Z
	R = dwindow.joystick.R
	U = dwindow.joystick.U
	V = dwindow.joystick.V
	POV_X = dwindow.joystick.PovX
	POV_Y = dwindow.joystick.PovY

	def __init__(self):
		raise NotImplementedError("This class is not meant to be instantiated!")
		
	@classmethod
	def is_connected(cls, unsigned int joystick):
		return dwindow.joystick.isConnected(joystick)

	@classmethod
	def get_button_count(cls, unsigned int joystick):
		return dwindow.joystick.getButtonCount(joystick)

	@classmethod
	def has_axis(cls, unsigned int joystick, int axis):
		return dwindow.joystick.hasAxis(joystick, <dwindow.joystick.Axis>axis)

	@classmethod
	def is_button_pressed(cls, unsigned int joystick, unsigned int button):
		return dwindow.joystick.isButtonPressed(joystick, button)

	@classmethod
	def get_axis_position(cls, unsigned int joystick, int axis):
		return dwindow.joystick.getAxisPosition(joystick, <dwindow.joystick.Axis> axis)

	@classmethod
	def update(cls):
		dwindow.joystick.update()


cdef class Mouse:
	LEFT = dwindow.mouse.Left
	RIGHT = dwindow.mouse.Right
	MIDDLE = dwindow.mouse.Middle
	X_BUTTON1 = dwindow.mouse.XButton1
	X_BUTTON2 = dwindow.mouse.XButton2
	BUTTON_COUNT = dwindow.mouse.ButtonCount
	
	def __init__(self):
		raise NotImplementedError("This class is not meant to be instantiated!")
		
	@classmethod
	def is_button_pressed(cls, int button):
		return dwindow.mouse.isButtonPressed(<dwindow.mouse.Button>button)

	@classmethod
	def get_position(cls, Window window=None):
		cdef dsystem.Vector2i p

		if window is None: p = dwindow.mouse.getPosition()
		else: p = dwindow.mouse.getPosition(window.p_window[0])

		return Position(p.x, p.y)

	@classmethod
	def set_position(cls, position, Window window=None):
		cdef dsystem.Vector2i p
		p.x, p.y = position

		if window is None: dwindow.mouse.setPosition(p)
		else: dwindow.mouse.setPosition(p, window.p_window[0])


cdef class Context:
	cdef dwindow.Context *p_this
	
	def __init__(self):
		self.p_this = new dwindow.Context()

	def __dealloc__(self):
		del self.p_this
		
	property active:			
		def __set__(self, bint active):
			self.p_this.setActive(active)
		
	
cdef Event wrap_event(dwindow.Event *p):
	cdef Event event = None
	
	if p.type == dwindow.event.Closed:
		pass
	elif p.type == dwindow.event.Resized:
		event = SizeEvent.__new__(SizeEvent)
	elif p.type == dwindow.event.LostFocus:
		pass
	elif p.type == dwindow.event.GainedFocus:
		pass
	elif p.type == dwindow.event.TextEntered:
		event = TextEvent.__new__(TextEvent)
	elif p.type == dwindow.event.KeyPressed or p.type == dwindow.event.KeyReleased:
		event = KeyEvent.__new__(KeyEvent)
	elif p.type == dwindow.event.MouseWheelMoved:
		event = MouseWheelEvent.__new__(MouseWheelEvent)
	elif p.type == dwindow.event.MouseButtonPressed or p.type == dwindow.event.MouseButtonReleased:
		event = MouseButtonEvent.__new__(MouseButtonEvent)
	elif p.type == dwindow.event.MouseMoved:
		event = MouseMoveEvent.__new__(MouseMoveEvent)
	elif p.type == dwindow.event.MouseEntered:
		pass
	elif p.type == dwindow.event.MouseLeft:
		pass
	elif p.type == dwindow.event.JoystickButtonPressed or p.type == dwindow.event.JoystickButtonReleased:
		event = JoystickButtonEvent.__new__(JoystickButtonEvent)
	elif p.type == dwindow.event.JoystickMoved:
		event = JoystickMoveEvent.__new__(JoystickMoveEvent)
	elif p.type == dwindow.event.JoystickConnected or p.type == dwindow.event.JoystickDisconnected:
		event = JoystickConnectEvent.__new__(JoystickConnectEvent)

	if not event: event = Event.__new__(Event)
	
	event.p_this = p
	return event

cdef VideoMode wrap_videomode(dwindow.VideoMode *p, bint d):
	cdef VideoMode r = VideoMode.__new__(VideoMode, 640, 480, 32)
	r.p_this = p
	r.delete_this = d
	return r

cdef ContextSettings wrap_contextsettings(dwindow.ContextSettings *v):
	cdef ContextSettings r = ContextSettings.__new__(ContextSettings)
	r.p_this = v
	return r


########################################################################
##                          Graphics Module                           ##
########################################################################

class BlendMode:
	BLEND_ALPHA = dgraphics.blendmode.BlendAlpha
	BLEND_ADD = dgraphics.blendmode.BlendAdd
	BLEND_MULTIPLY = dgraphics.blendmode.BlendMultiply
	BLEND_NONE = dgraphics.blendmode.BlendNone


class PrimitiveType:
	POINTS = dgraphics.primitivetype.Points
	LINES = dgraphics.primitivetype.Lines
	LINES_STRIP = dgraphics.primitivetype.LinesStrip
	TRIANGLES = dgraphics.primitivetype.Triangles
	TRIANGLES_STRIP = dgraphics.primitivetype.TrianglesStrip
	TRIANGLES_FAN = dgraphics.primitivetype.TrianglesFan
	QUADS = dgraphics.primitivetype.Quads


cdef class Color:
	BLACK = Color(0, 0, 0)
	WHITE = Color(255, 255, 255)
	RED = Color(255, 0, 0)
	GREEN = Color(0, 255, 0)
	BLUE = Color(0, 0, 255)
	YELLOW = Color(255, 255, 0)
	MAGENTA = Color(255, 0, 255)
	CYAN = Color(0, 255, 255)
	TRANSPARENT = Color(0, 0, 0, 0)

	cdef dgraphics.Color *p_this

	def __init__(self, Uint8 r, Uint8 g, Uint8 b, Uint8 a=255):
		self.p_this = new dgraphics.Color(r, g, b, a)

	def __dealloc__(self):
		del self.p_this

	def __repr__(self):
		return 'sf.Color({0})'.format(self)
		
	def __str__(self):
		return "{0}r, {1}g, {2}b, {3}a".format(self.r, self.g, self.b, self.a)
		
	def __richcmp__(Color x, Color y, int op):
		if op == 2: return x.p_this[0] == y.p_this[0]
		elif op == 3: return x.p_this[0] != y.p_this[0]
		else: return NotImplemented

	def __add__(Color x, Color y):
		r = Color(0, 0, 0)
		r.p_this[0] = x.p_this[0] + y.p_this[0]
		return r
		
	def __mul__(Color x, Color y):
		r = Color(0, 0, 0)
		r.p_this[0] = x.p_this[0] * y.p_this[0]
		return r

	def __iadd__(self, Color x):
		self.p_this[0] = self.p_this[0] + x.p_this[0]
		return self

	def __imul__(self, Color x):
		self.p_this[0] = self.p_this[0] * x.p_this[0]
		return self

	property r:
		def __get__(self):
			return self.p_this.r

		def __set__(self, Uint8 r):
			self.p_this.r = r

	property g:
		def __get__(self):
			return self.p_this.g

		def __set__(self, Uint8 g):
			self.p_this.g = g

	property b:
		def __get__(self):
			return self.p_this.b

		def __set__(self, Uint8 b):
			self.p_this.b = b

	property a:
		def __get__(self):
			return self.p_this.a

		def __set__(self, unsigned int a):
			self.p_this.a = a


cdef Color wrap_color(dgraphics.Color *p):
	cdef Color r = Color.__new__(Color)
	r.p_this = p
	return r


cdef class Transform:
	cdef dgraphics.Transform *p_this
	cdef bint                 delete_this
	
	def __init__(self):
		self.p_this = new dgraphics.Transform()
		self.delete_this = True

	def __dealloc__(self):
		if self.delete_this:
			del self.p_this

	def __repr__(self):
		cdef float *p = <float*>self.p_this.getMatrix()
		return "sf.Transform({0}, {1}, {2}, {3}, {4}, {5}, {6}, {7}, {8})".format(p[0], p[1], p[2], p[3], p[4], p[5], p[6], p[7], p[8])

	def __str__(self):
		cdef float *p = <float*>self.p_this.getMatrix()
		return "[{0}, {1}, {2}]\n[{3}, {4}, {5}]\n[{6}, {7}, {8}]".format(str(p[0])[:3], str(p[1])[:3], str(p[2])[:3], str(p[3])[:3], str(p[7])[:3], str(p[5])[:3], str(p[6])[:3], str(p[7])[:3], str(p[8])[:3])

	def __mul__(Transform x, Transform y):
		r = Transform()
		r.p_this[0] = x.p_this[0] * y.p_this[0]
		return r

	def __imul__(self, Transform x):
		self.p_this[0] = self.p_this[0] * x.p_this[0]
		return self
		
	@classmethod
	def from_values(self, float a00, float a01, float a02, float a10, float a11, float a12, float a20, float a21, float a22):
		cdef Transform r = Transform.__new__(Transform)
		r.p_this = new dgraphics.Transform(a00, a01, a02, a10, a11, a12, a20, a21, a22)
		return r

	property matrix:
		def __get__(self):
			return <long>self.p_this.getMatrix()
		
	property inverse:
		def __get__(self):
			cdef dgraphics.Transform *p = new dgraphics.Transform()
			p[0] = self.p_this.getInverse()
			return wrap_transform(p)
	
	def transform_point(self, point):
		cdef dsystem.Vector2f p = self.p_this.transformPoint(position_to_vector2f(point))
		return Position(p.x, p.y)
		
	def transform_rectangle(self, rectangle):
		cdef dsystem.FloatRect p = self.p_this.transformRect(rectangle_to_floatrect(rectangle))
		return Rectangle((p.top, p.left), (p.width, p.height))
		
	def combine(self, Transform transform):
		self.p_this.combine(transform.p_this[0])
		return self
		
	def translate(self, offset):
		self.p_this.translate(position_to_vector2f(offset))
		return self
		
	def rotate(self, float angle, center=None):
		if not center:
			self.p_this.rotate(angle)
		else:
			self.p_this.rotate(angle, position_to_vector2f(center))
			
		return self
		
	def scale(self, factor, center=None):
		if not center:
			self.p_this.scale(position_to_vector2f(factor))
		else:
			self.p_this.scale(position_to_vector2f(factor), position_to_vector2f(center))
			
		return self
		
		
cdef Transform wrap_transform(dgraphics.Transform *p, bint d=True):
	cdef Transform r = Transform.__new__(Transform)
	r.p_this = p
	r.delete_this = d
	return r


cdef class Pixels:
	cdef const_Uint8_ptr p_array
	cdef unsigned int    m_width
	cdef unsigned int    m_height
	
	def __init__(self):
		raise UserWarning("Not meant to be constructed")
	
	def __getitem__(self, unsigned int index):
		return self.p_this[index]


cdef Pixels wrap_pixels(const_Uint8_ptr p, unsigned int w, unsigned int h):
	cdef Pixels r = Pixels.__new__(Pixels)
	r.p_array, r.m_width, r.m_height = p, w, h
	return r
	

cdef class Image:
	cdef dgraphics.Image *p_this
	
	def __init__(self):
		raise UserWarning("Use a specific constructor")

	def __dealloc__(self):
		del self.p_this
		
	def __getitem__(self, tuple v):
		cdef dgraphics.Color *p = new dgraphics.Color()
		p[0] = self.p_this.getPixel(v[0], v[1])
		return wrap_color(p)

	def __setitem__(self, tuple k, Color v):
		self.p_this.setPixel(k[0], k[1], v.p_this[0])

	@classmethod
	def create(cls, unsigned int width, unsigned int height, Color color=None):
		cdef dgraphics.Image *p = new dgraphics.Image()
		if not color: p.create(width, height)
		else: raise NotImplementedError("Not implemented due to a bug in Cython, see task #74 in the bug tracker: http://openhelbreath.net/python-sfml2/flyspray/")
		return wrap_image(p)

	@classmethod
	def create_from_pixels(cls, Pixels pixels):
		cdef dgraphics.Image *p
		
		if pixels.p_array != None:
			p = new dgraphics.Image()
			p.create(pixels.m_width, pixels.m_height, pixels.p_array)
			return wrap_image(p)
			
		raise SFMLException("sf.Pixels's array points on NULL - It would create an empty image")

	@classmethod
	def load_from_file(cls, filename):
		cdef dgraphics.Image *p = new dgraphics.Image()
		cdef char* encoded_filename	

		encoded_filename_temporary = filename.encode('UTF-8')	
		encoded_filename = encoded_filename_temporary

		if p.loadFromFile(encoded_filename):
			return wrap_image(p)

		del p
		raise SFMLException()

	@classmethod
	def load_from_memory(cls, bytes data):
		cdef dgraphics.Image *p = new dgraphics.Image()

		if p.loadFromMemory(<char*>data, len(data)):
			return wrap_image(p)
			
		del p
		raise SFMLException()

	def save_to_file(self, filename):
		cdef char* encoded_filename	
			
		encoded_filename_temporary = filename.encode('UTF-8')	
		encoded_filename = encoded_filename_temporary

		if not self.p_this.saveToFile(encoded_filename): raise SFMLException()
	
	property size:
		def __get__(self):
			return Size(self.p_this.getSize().x, self.p_this.getSize().y)
		
	property width:
		def __get__(self):
			return self.size.width
	
	property height:
		def __get__(self):
			return self.size.height
	
	def create_mask_from_color(self, Color color, Uint8 alpha=0):
		self.p_this.createMaskFromColor(color.p_this[0], alpha)
	
	def blit(self, Image source, dest, source_rect=None, bint apply_alpha=False):
		x, y = dest
		if not source_rect: self.p_this.copy(source.p_this[0], x, y, dsystem.IntRect(0, 0, 0, 0), apply_alpha)
		else: self.p_this.copy(source.p_this[0], x, y, rectangle_to_intrect(source_rect), apply_alpha)
	
	property pixels:
		def __get__(self):
			if self.p_this.getPixelsPtr() != None:
				return wrap_pixels(self.p_this.getPixelsPtr(), self.width, self.height)
		
	def flip_horizontally(self):
		self.p_this.flipHorizontally()
		
	def flip_vertically(self):
		self.p_this.flipVertically()

	def copy(self):
		cdef dgraphics.Image *p = new dgraphics.Image()
		p[0] = self.p_this[0]
		return wrap_image(p)

cdef Image wrap_image(dgraphics.Image *p):
	cdef Image r = Image.__new__(Image)
	r.p_this = p
	return r


cdef class Texture:
	NORMALIZED = dgraphics.texture.Normalized
	PIXELS = dgraphics.texture.Pixels
	
	cdef dgraphics.Texture *p_this
	cdef bint               delete_this
	
	def __init__(self):
		raise UserWarning("Use a specific constructor")

	def __dealloc__(self):
		if self.delete_this: del self.p_this

	@classmethod
	def create(cls, unsigned int width, unsigned int height):
		cdef dgraphics.Texture *p = new dgraphics.Texture()
		
		if p.create(width, height):
			return wrap_texture(p)
		
		del p
		raise SFMLException()

	@classmethod
	def load_from_file(cls, filename, area=None):
		cdef dgraphics.Texture *p = new dgraphics.Texture()
		cdef char* encoded_filename
		
		encoded_filename_temporary = filename.encode('UTF-8')	
		encoded_filename = encoded_filename_temporary
		
		if not area:
			if p.loadFromFile(encoded_filename): return wrap_texture(p)
		else:
			l, t, w, h = area
			if p.loadFromFile(encoded_filename, dsystem.IntRect(l, t, w, h)): return wrap_texture(p)
			
		del p
		raise SFMLException()
		
	@classmethod
	def load_from_memory(cls, bytes data, area=None):
		cdef dgraphics.Texture *p = new dgraphics.Texture()
		
		if not area:
			if p.loadFromMemory(<char*>data, len(data)): return wrap_texture(p)
		else:
			l, t, w, h = area
			if p.loadFromMemory(<char*>data, len(data), dsystem.IntRect(l, t, w, h)): return wrap_texture(p)
	
		del p
		raise SFMLException()
		
	@classmethod
	def load_from_image(cls, Image image, area=None):
		cdef dgraphics.Texture *p = new dgraphics.Texture()
		
		if not area:
			if p.loadFromImage(image.p_this[0]): return wrap_texture(p)
		else:
			l, t, w, h = area
			if p.loadFromImage(image.p_this[0], dsystem.IntRect(l, t, w, h)): return wrap_texture(p)
		
		del p
		raise SFMLException()

	property size:
		def __get__(self):
			return Size(self.p_this.getSize().x, self.p_this.getSize().y)
			
		def __set__(self, size):
			raise NotImplemented
	
	property width:
		def __get__(self):
			return self.size.width
			
		def __set__(self, width):
			raise NotImplemented
	
	property height:
		def __get__(self):
			return self.size.height
			
		def __set__(self, height):
			raise NotImplemented

	def copy_to_image(self):
		cdef dgraphics.Image *p = new dgraphics.Image()
		p[0] = self.p_this.copyToImage()
		return wrap_image(p)
	
	def update(self): raise NotImplemented
	
	def update_from_pixels(self, Pixels pixels, area=None):
		if not area:
			self.p_this.update(pixels.p_array)
		else:
			l, t, w, h = area
			self.p_this.update(pixels.p_array, w, h, l, t)
			
	def update_from_image(self, Image image, position=None):
		if not position:
			self.p_this.update(image.p_this[0])
		else:
			#x, y = position
			#self.p_this.update(image.p_this[0], x, y)
			raise NotImplementedError("Not implemented due to a bug in Cython, see task #76 in the bug tracker: http://openhelbreath.net/python-sfml2/flyspray/")
		
	def update_from_window(self, Window window, position=None):
		if not position:
			self.p_this.update(window.p_window[0])
		else:
			#x, y = position
			#self.p_this.update(window.p_this[0], x, y)
			raise NotImplementedError("Not implemented due to a bug in Cython, see task #77 in the bug tracker: http://openhelbreath.net/python-sfml2/flyspray/")
			
	def bind(self, dgraphics.texture.CoordinateType coordinate_type=dgraphics.texture.Normalized):
		self.p_this.bind(coordinate_type)

	property smooth:
		def __get__(self):
			return self.p_this.isSmooth()
			
		def __set__(self, bint smooth):
			self.p_this.setSmooth(smooth)
		
	property repeated:
		def __get__(self):
			return self.p_this.isRepeated()
			
		def __set__(self, bint repeated):
			self.p_this.setRepeated(repeated)

	def copy(self):
		cdef dgraphics.Texture *p = new dgraphics.Texture()
		p[0] = self.p_this[0]
		return wrap_texture(p)
		
	@classmethod
	def get_maximum_size(cls):
		return dgraphics.texture.getMaximumSize()
		
		
cdef Texture wrap_texture(dgraphics.Texture *p, bint d=True):
	cdef Texture r = Texture.__new__(Texture)
	r.p_this = p
	r.delete_this = d
	return r


cdef class Glyph:
	cdef dgraphics.Glyph *p_this

	def __init__(self):
		self.p_this = new dgraphics.Glyph()

	def __dealloc__(self):
		del self.p_this

	property advance:
		def __get__(self):
			return self.p_this.advance

		def __set__(self, int advance):
			self.p_this.advance = advance

	property bounds:
		def __get__(self):
			return intrect_to_rectangle(&self.p_this.bounds)
			
		def __set__(self, bounds):
			l, t, w, h = bounds
			self.p_this.bounds = dsystem.IntRect(l, t, w, h)

	property texture_rectangle:
		def __get__(self):
			return intrect_to_rectangle(&self.p_this.textureRect)
			
		def __set__(self, texture_rectangle):
			l, t, w, h = texture_rectangle
			self.p_this.textureRect = dsystem.IntRect(l, t, w, h)


cdef Glyph wrap_glyph(dgraphics.Glyph *p):
	cdef Glyph r = Glyph.__new__(Glyph)
	r.p_this = p
	return r


cdef class Font:
	cdef dgraphics.Font *p_this
	cdef bint            delete_this
	cdef Texture         m_texture
	
	def __init__(self):
		raise UserWarning("Use a specific constructor")

	def __dealloc__(self):
		if self.delete_this: del self.p_this

	@classmethod
	def load_from_file(cls, filename):
		cdef dgraphics.Font *p = new dgraphics.Font()
		cdef char* encoded_filename	

		encoded_filename_temporary = filename.encode('UTF-8')	
		encoded_filename = encoded_filename_temporary

		if p.loadFromFile(encoded_filename):
			return wrap_font(p)

		del p
		raise SFMLException()

	@classmethod
	def load_from_memory(cls, bytes data):
		cdef dgraphics.Font *p = new dgraphics.Font()

		if p.loadFromMemory(<char*>data, len(data)):
			return wrap_font(p)
			
		del p
		raise SFMLException()

	def get_glyph(self, Uint32 code_point, unsigned int character_size, bint bold):
		cdef dgraphics.Glyph *p = new dgraphics.Glyph()
		p[0] = self.p_this.getGlyph(code_point, character_size, bold)
		return wrap_glyph(p)

	def get_kerning(self, Uint32 first, Uint32 second, unsigned int character_size):
		return self.p_this.getKerning(first, second, character_size)

	def get_line_spacing(self, unsigned int character_size):
		return self.p_this.getLineSpacing(character_size)

	def get_texture(self, unsigned int character_size):
		cdef dgraphics.Texture *p
		p = <dgraphics.Texture*>&self.p_this.getTexture(character_size)
		return wrap_texture(p, False)

	@classmethod
	def get_default_font(cls):
		return wrap_font(<dgraphics.Font*>&dgraphics.font.getDefaultFont(), False)

cdef Font wrap_font(dgraphics.Font *p, bint d=True):
	cdef Font r = Font.__new__(Font)
	r.p_this = p
	r.delete_this = d
	return r

	
cdef class Shader:
	cdef dgraphics.Shader *p_this
	cdef bint              delete_this
	
	def __init__(self):
		raise UserWarning("Use a specific constructor")

	def __dealloc__(self):
		if self.delete_this: del self.p_this

	@classmethod
	def load_from_file(cls, vertex_filename, fragment_filename):
		cdef dgraphics.Shader *p = new dgraphics.Shader()
		cdef char* encoded_vertex_filename
		cdef char* encoded_fragment_filename
		
		encoded_vertex_filename_temporary = vertex_filename.encode('utf-8')	
		encoded_vertex_filename = encoded_vertex_filename_temporary
						
		encoded_fragment_filename_temporary = fragment_filename.encode('utf-8')	
		encoded_fragment_filename = encoded_fragment_filename_temporary
	
		if p.loadFromFile(encoded_vertex_filename, encoded_fragment_filename):
			return wrap_shader(p)
		
		del p
		raise SFMLException()
		
	@classmethod
	def load_vertex_from_file(cls, filename):
		cdef dgraphics.Shader *p = new dgraphics.Shader()
		cdef char* encoded_filename
		
		encoded_filename_temporary = filename.encode('utf-8')	
		encoded_filename = encoded_filename_temporary
		
		if p.loadFromFile(encoded_filename, dgraphics.shader.Vertex):
			return wrap_shader(p)
		
		del p
		raise SFMLException()
		
	@classmethod
	def load_fragment_from_file(cls, filename):
		cdef dgraphics.Shader *p = new dgraphics.Shader()
		cdef char* encoded_filename
		
		encoded_filename_temporary = filename.encode('utf-8')	
		encoded_filename = encoded_filename_temporary
		
		if p.loadFromFile(encoded_filename, dgraphics.shader.Fragment):
			return wrap_shader(p)
		
		del p
		raise SFMLException()
		
	@classmethod
	def load_from_memory(cls, char* vertex, char* fragment):
		cdef dgraphics.Shader *p = new dgraphics.Shader()

		if p.loadFromMemory(vertex, fragment):
			return wrap_shader(p)
			
		del p
		raise SFMLException()
		
	@classmethod
	def load_vertex_from_memory(cls, char* vertex):
		cdef dgraphics.Shader *p = new dgraphics.Shader()

		if p.loadFromMemory(vertex, dgraphics.shader.Vertex):
			return wrap_shader(p)
			
		del p
		raise SFMLException()
		
	@classmethod
	def load_fragment_from_memory(cls, char* fragment):
		cdef dgraphics.Shader *p = new dgraphics.Shader()

		if p.loadFromMemory(fragment, dgraphics.shader.Fragment):
			return wrap_shader(p)
			
		del p
		raise SFMLException()

	def set_parameter(self, *args, **kwargs):
		if len(args) == 0:
			raise UserWarning("No arguments provided. It requires at least one string.")
			
		if type(args[0]) not in [bytes, unicode, str]:
			raise UserWarning("The first argument must be a string (bytes, unicode or str)")

		if len(args) == 1:
			self.set_currenttexturetype_parameter(args[0])
		elif len(args) == 2:
			if type(args[1]) in [Position, tuple]:
				if type(args[1]) is Position:
					self.set_vector2_paramater(args[0], args[1])
					return
				elif len(args[1]) == 2:
					self.set_vector2_paramater(args[0], args[1])
				elif len(args[1]) == 3:
					self.set_vector3_paramater(args[0], args[1])
				else:
					raise UserWarning("The second argument must be a tuple of length 2 or 3")
			elif type(args[1]) is Color:
				self.set_color_parameter(args[0], args[1])
			elif type(args[1]) is Transform:
				self.set_transform_parameter(args[0], args[1])
			elif type(args[1]) is Texture:
				self.set_texture_parameter(args[0], args[1])
			elif type(args[1]) in numeric_type:
				self.set_1float_parameter(args[0], args[1])
			else:
				raise UserWarning("The second argument type must be a number, an sf.Position, an sf.Color, an sf.Transform or an sf.Texture")
		else:
			if len(args) > 5:
				raise UserWarning("Wrong number of argument.")
			for i in range(1, len(args)):
				if type(args[i]) not in numeric_type:
					raise UserWarning("Argument {0} must be a number".format(i+1))
			if len(args) == 3:
				self.set_2float_parameter(args[0], args[1], args[2])
			elif len(args) == 4:
				self.set_3float_parameter(args[0], args[1], args[2], args[3])
			else:
				self.set_4float_parameter(args[0], args[1], args[2], args[3], args[4])

	def set_1float_parameter(self, name, float x):
		cdef char* encoded_name
		
		encoded_name_temporary = name.encode('UTF-8')	
		encoded_name = encoded_name_temporary
		
		self.p_this.setParameter(encoded_name, x)

	def set_2float_parameter(self, name, float x, float y):
		cdef char* encoded_name
		
		encoded_name_temporary = name.encode('UTF-8')	
		encoded_name = encoded_name_temporary
		
		self.p_this.setParameter(encoded_name, x, y)

	def set_3float_parameter(self, name, float x, float y, float z):
		cdef char* encoded_name
		
		encoded_name_temporary = name.encode('UTF-8')	
		encoded_name = encoded_name_temporary
		
		self.p_this.setParameter(encoded_name, x, y, z)

	def set_4float_parameter(self, name, float x, float y, float z, float w):
		cdef char* encoded_name
		
		encoded_name_temporary = name.encode('UTF-8')	
		encoded_name = encoded_name_temporary
		
		self.p_this.setParameter(encoded_name, x, y, z, w)

	def set_vector2_paramater(self, name, vector): 
		cdef char* encoded_name
		
		encoded_name_temporary = name.encode('UTF-8')	
		encoded_name = encoded_name_temporary
		
		self.p_this.setParameter(encoded_name, position_to_vector2f(vector))
	
	def set_vector3_paramater(self, name, tuple vector): 
		cdef char* encoded_name
		
		encoded_name_temporary = name.encode('UTF-8')	
		encoded_name = encoded_name_temporary

		x, y, z = vector
		self.p_this.setParameter(encoded_name, dsystem.Vector3f(x, y, z))
	
	def set_color_parameter(self, name, Color color): 
		cdef char* encoded_name
		
		encoded_name_temporary = name.encode('UTF-8')	
		encoded_name = encoded_name_temporary
		
		self.p_this.setParameter(encoded_name, color.p_this[0])
	
	def set_transform_parameter(self, name, Transform transform): 
		cdef char* encoded_name
		
		encoded_name_temporary = name.encode('UTF-8')	
		encoded_name = encoded_name_temporary
		
		self.p_this.setParameter(encoded_name, transform.p_this[0])
	
	def set_texture_parameter(self, name, Texture texture): 
		cdef char* encoded_name
		
		encoded_name_temporary = name.encode('UTF-8')	
		encoded_name = encoded_name_temporary
		
		self.p_this.setParameter(encoded_name, texture.p_this[0])
	
	def set_currenttexturetype_parameter(self, name): 
		cdef char* encoded_name
		
		encoded_name_temporary = name.encode('UTF-8')	
		encoded_name = encoded_name_temporary
		
		self.p_this.setParameter(encoded_name, dgraphics.shader.CurrentTexture)
	
	def bind(self):
		self.p_this.bind()

	def unbind(self):
		self.p_this.unbind()
		
	@classmethod
	def is_available(cls):
		return dgraphics.shader.isAvailable()


cdef Shader wrap_shader(dgraphics.Shader *p, bint d=True):
	cdef Shader r = Shader.__new__(Shader)
	r.p_this = p
	r.delete_this = d
	return r


cdef class RenderStates:
	DEFAULT = wrap_renderstates(<dgraphics.RenderStates*>&dgraphics.renderstates.Default, False)
	
	cdef dgraphics.RenderStates *p_this
	cdef bint                    delete_this
	cdef Transform               m_transform
	cdef Texture                 m_texture
	cdef Shader                  m_shader
	
	def __init__(self, dgraphics.blendmode.BlendMode blend_mode=dgraphics.blendmode.BlendAlpha, Transform transform=None, Texture texture=None, Shader shader=None):
		self.p_this = new dgraphics.RenderStates()
		
		self.m_transform = wrap_transform(&self.p_this.transform, False)
		self.m_texture = None
		self.m_shader = None
		
		if blend_mode: self.blend_mode = blend_mode
		if transform: self.transform = transform
		if texture: self.texture = texture
		if shader: self.shader = shader

	def __dealloc__(self):
		if self.delete_this: del self.p_this

	property blend_mode:
		def __get__(self):
			return self.p_this.blendMode
			
		def __set__(self, dgraphics.blendmode.BlendMode blend_mode):
			self.p_this.blendMode = blend_mode

	property transform:
		def __get__(self):
			return self.m_transform
			
		def __set__(self, Transform transform):
			self.p_this.transform = transform.p_this[0]

	property texture:
		def __get__(self):
			return self.m_texture
			
		def __set__(self, Texture texture):
			self.p_this.texture = texture.p_this			
			self.m_texture = texture
			
	property shader:
		def __get__(self):
			return self.m_shader
			
		def __set__(self, Shader shader):
			self.p_this.shader = shader.p_this			
			self.m_shader = shader

cdef RenderStates wrap_renderstates(dgraphics.RenderStates *p, bint d=True):
	cdef RenderStates r = RenderStates.__new__(RenderStates)
	r.p_this = p
	r.delete_this = d
	r.m_transform = wrap_transform(&p.transform, False)
	if p.texture: r.m_texture = wrap_texture(<dgraphics.Texture*>p.texture, False)
	else: r.m_texture = None
	if p.shader: r.m_shader = wrap_shader(<dgraphics.Shader*>p.shader, False)
	else: r.m_shader = None
	return r
	
cdef api object api_wrap_renderstates(dgraphics.RenderStates *p):
	cdef RenderStates r = RenderStates.__new__(RenderStates)
	r.p_this = p
	r.delete_this = False
	r.m_transform = wrap_transform(&p.transform, False)
	if p.texture: r.m_texture = wrap_texture(<dgraphics.Texture*>p.texture, False)
	else: r.m_texture = None
	if p.shader: r.m_shader = wrap_shader(<dgraphics.Shader*>p.shader, False)
	else: r.m_shader = None
	return r

cdef class Drawable:
	cdef dgraphics.Drawable *p_drawable
	
	def __cinit__(self, *args, **kwargs):
		if self.__class__ == Drawable:
			raise NotImplementedError('Drawable is abstact')
		elif self.__class__ not in [Shape, Sprite, Text, VertexArray]:
			self.p_drawable = <dgraphics.Drawable*>new dgraphics.DerivableDrawable(<void*>self)
			
	def draw(self, target, states): pass
	
	
cdef class Transformable:
	cdef dgraphics.Transformable *p_this
	
	def __cinit__(self):
		self.p_this = new dgraphics.Transformable()

	def __dealloc__(self):
		del self.p_this

	property position:
		def __get__(self):
			return Position(self.p_this.getPosition().x, self.p_this.getPosition().y)
			
		def __set__(self, position):
			self.p_this.setPosition(position_to_vector2f(position))
		
	property rotation:
		def __get__(self):
			return self.p_this.getRotation()
			
		def __set__(self, float angle):
			self.p_this.setRotation(angle)
		
	property ratio:
		def __get__(self):
			return Position(self.p_this.getScale().x, self.p_this.getScale().y)
			
		def __set__(self, factor):
			self.p_this.setScale(position_to_vector2f(factor))
		
	property origin:
		def __get__(self):
			return Position(self.p_this.getOrigin().x, self.p_this.getOrigin().y)
			
		def __set__(self, origin):
			self.p_this.setOrigin(position_to_vector2f(origin))
		
	def move(self, offset):
		self.p_this.move(position_to_vector2f(offset))
		
	def rotate(self, float angle):
		self.p_this.rotate(angle)

	def scale(self, factor):
		self.p_this.scale(position_to_vector2f(factor))
				
	property transform:
		def __get__(self):
			cdef dgraphics.Transform *p = new dgraphics.Transform()
			p[0] = self.p_this.getTransform()
			return wrap_transform(p)
		
	property inverse_transform:
		def __get__(self):
			cdef dgraphics.Transform *p = new dgraphics.Transform()
			p[0] = self.p_this.getInverseTransform()
			return wrap_transform(p)


cdef class TransformableDrawable(Drawable):
	cdef dgraphics.Transformable *p_transformable
	
	def __cinit__(self, *args, **kwargs):
		if self.__class__ == TransformableDrawable:
			raise NotImplementedError('TransformableDrawable is abstact')

	property position:
		def __get__(self):
			return Position(self.p_transformable.getPosition().x, self.p_transformable.getPosition().y)
			
		def __set__(self, position):
			self.p_transformable.setPosition(position_to_vector2f(position))
		
	property rotation:
		def __get__(self):
			return self.p_transformable.getRotation()
			
		def __set__(self, float angle):
			self.p_transformable.setRotation(angle)
		
	property ratio:
		def __get__(self):
			return Position(self.p_transformable.getScale().x, self.p_transformable.getScale().y)
			
		def __set__(self, factor):
			self.p_transformable.setScale(position_to_vector2f(factor))
		
	property origin:
		def __get__(self):
			return Position(self.p_transformable.getOrigin().x, self.p_transformable.getOrigin().y)
			
		def __set__(self, origin):
			self.p_transformable.setOrigin(position_to_vector2f(origin))
		
	def move(self, offset):
		self.p_transformable.move(position_to_vector2f(offset))
		
	def rotate(self, float angle):
		self.p_transformable.rotate(angle)
		
	def scale(self, factor):
		self.p_transformable.scale(position_to_vector2f(factor))
		
	property transform:
		def __get__(self):
			cdef dgraphics.Transform *p = new dgraphics.Transform()
			p[0] = self.p_transformable.getTransform()
			return wrap_transform(p)
		
	property inverse_transform:
		def __get__(self):
			cdef dgraphics.Transform *p = new dgraphics.Transform()
			p[0] = self.p_transformable.getInverseTransform()
			return wrap_transform(p)
			
			
cdef class Sprite(TransformableDrawable):
	cdef dgraphics.Sprite *p_this
	cdef Texture           m_texture
	
	def __cinit__(self, Texture texture, rectangle=None):
		if not rectangle: self.p_this = new dgraphics.Sprite(texture.p_this[0])
		else:
			l, t, w, h = rectangle
			self.p_this = new dgraphics.Sprite(texture.p_this[0], dsystem.IntRect(l, t, w, h))
			
		self.p_drawable = <dgraphics.Drawable*>self.p_this
		self.p_transformable = <dgraphics.Transformable*>self.p_this
		
		self.m_texture = texture
		
	def __dealloc__(self):
		del self.p_this

	property texture:
		def __get__(self):
			return self.m_texture

		def __set__(self, Texture texture):
			self.p_this.setTexture(texture.p_this[0], True)
			self.m_texture = texture

	property texture_rectangle:
		def __get__(self):
			return intrect_to_rectangle(<dsystem.IntRect*>(&self.p_this.getTextureRect()))
			
		def __set__(self, rectangle):
			self.p_this.setTextureRect(rectangle_to_intrect(rectangle))

	property color:
		def __get__(self):
			cdef dgraphics.Color* p = new dgraphics.Color()
			p[0] = self.p_this.getColor()
			return wrap_color(p)
			
		def __set__(self, Color color):
			self.p_this.setColor(color.p_this[0])

	property local_bounds:
		def __get__(self):
			cdef dsystem.FloatRect p = self.p_this.getLocalBounds()
			return floatrect_to_rectangle(&p)
		
	property global_bounds:
		def __get__(self):
			cdef dsystem.FloatRect p = self.p_this.getGlobalBounds()
			return floatrect_to_rectangle(&p)


cdef class Text(TransformableDrawable):
	REGULAR    = dgraphics.text.Regular
	BOLD       = dgraphics.text.Bold
	ITALIC     = dgraphics.text.Italic
	UNDERLINED = dgraphics.text.Underlined

	cdef dgraphics.Text *p_this
	cdef Font            m_font

	def __init__(self, string=None, Font font=None, unsigned int character_size=30):
		self.p_this = new dgraphics.Text()
		self.p_drawable = <dgraphics.Drawable*>self.p_this
		self.p_transformable = <dgraphics.Transformable*>self.p_this
		
		if string: self.string = string
		if font: self.font = font
		self.character_size = character_size

	def __dealloc__(self):
		del self.p_this

	property string:
		def __get__(self):
			cdef char* decoded_string
			decoded_string = <char*>self.p_this.getString().toAnsiString().c_str()
			
			return decoded_string.decode('utf-8')

		def __set__(self, string):
			cdef char* encoded_string	

			encoded_string_temporary = string.encode('utf-8')	
			encoded_string = encoded_string_temporary
			
			self.p_this.setString(dgraphics.String(encoded_string))
					
	property font:
		def __get__(self):
			return self.m_font
			
		def __set__(self, Font font):
			self.p_this.setFont(font.p_this[0])
			self.m_font = font

	property character_size:
		def __get__(self):
			return self.p_this.getCharacterSize()
			
		def __set__(self, unsigned int size):
			self.p_this.setCharacterSize(size)

	property style:
		def __get__(self):
			return self.p_this.getStyle()
			
		def __set__(self, Uint32 style):
			self.p_this.setStyle(style)

	property color:
		def __get__(self):
			cdef dgraphics.Color* p = new dgraphics.Color()
			p[0] = self.p_this.getColor()
			return wrap_color(p)
			
		def __set__(self, Color color):
			self.p_this.setColor(color.p_this[0])

	property local_bounds:
		def __get__(self):
			cdef dsystem.FloatRect p = self.p_this.getLocalBounds()
			return floatrect_to_rectangle(&p)

	property global_bounds:
		def __get__(self):
			cdef dsystem.FloatRect p = self.p_this.getGlobalBounds()
			return floatrect_to_rectangle(&p)

	def find_character_pos(self, size_t index):
		cdef dsystem.Vector2f p = self.p_this.findCharacterPos(index)
		return Position(p.x, p.y)


cdef class Shape(TransformableDrawable):
	cdef dgraphics.Shape *p_shape
	cdef Texture          m_texture
	
	def __cinit__(self, *args, **kwargs):
		if self.__class__ == Shape:
			raise NotImplementedError('Shape is abstact')

	property texture:
		def __get__(self):
			return self.m_texture

		def __set__(self, Texture texture):
			if texture:
				self.p_shape.setTexture(texture.p_this, True)
				self.m_texture = texture
			else:
				self.p_shape.setTexture(NULL)
				self.m_texture = None

	property texture_rectangle:
		def __get__(self):
			return intrect_to_rectangle(<dsystem.IntRect*>(&self.p_shape.getTextureRect()))
			
		def __set__(self, rectangle):
			self.p_shape.setTextureRect(rectangle_to_intrect(rectangle))
		
	property fill_color:
		def __get__(self):
			cdef dgraphics.Color* p = new dgraphics.Color()
			p[0] = self.p_shape.getFillColor()
			return wrap_color(p)
			
		def __set__(self, Color color):
			self.p_shape.setFillColor(color.p_this[0])

	property outline_color:
		def __get__(self):
			cdef dgraphics.Color* p = new dgraphics.Color()
			p[0] = self.p_shape.getOutlineColor()
			return wrap_color(p)
			
		def __set__(self, Color color):
			self.p_shape.setOutlineColor(color.p_this[0])
		
	property outline_thickness:
		def __get__(self):
			return self.p_shape.getOutlineThickness()
			
		def __set__(self, float thickness):
			self.p_shape.setOutlineThickness(thickness)
		
	property local_bounds:
		def __get__(self):
			cdef dsystem.FloatRect p = self.p_shape.getLocalBounds()
			return floatrect_to_rectangle(&p)

	property global_bounds:
		def __get__(self):
			cdef dsystem.FloatRect p = self.p_shape.getGlobalBounds()
			return floatrect_to_rectangle(&p)

	property point_count:
		def __get__(self):
			return self.p_shape.getPointCount()
			
	def get_point(self, unsigned int index):
		return Position(self.p_shape.getPoint(index).x, self.p_shape.getPoint(index).y)


cdef class CircleShape(Shape):
	cdef dgraphics.CircleShape *p_this
	
	def __cinit__(self, float radius=0, unsigned int point_count=30):
		self.p_this = new dgraphics.CircleShape(radius, point_count)

		self.p_drawable = <dgraphics.Drawable*>self.p_this
		self.p_transformable = <dgraphics.Transformable*>self.p_this
		self.p_shape = <dgraphics.Shape*>self.p_this
		
	def __dealloc__(self):
		del self.p_this
		
	property radius:
		def __get__(self):
			return self.p_this.getRadius()
			
		def __set__(self, float radius):
			self.p_this.setRadius(radius)
		
	property point_count:
		def __get__(self):
			return self.p_this.getPointCount()
			
		def __set__(self, unsigned int count):
			self.p_this.setPointCount(count)


cdef class ConvexShape(Shape):
	cdef dgraphics.ConvexShape *p_this
	
	def __cinit__(self, unsigned int point_count=0):
		self.p_this = new dgraphics.ConvexShape(point_count)
		self.p_drawable = <dgraphics.Drawable*>self.p_this
		self.p_transformable = <dgraphics.Transformable*>self.p_this
		self.p_shape = <dgraphics.Shape*>self.p_this
		
	def __dealloc__(self):
		del self.p_this

	property point_count:
		def __get__(self):
			return self.p_this.getPointCount()
			
		def __set__(self, unsigned int count):
			self.p_this.setPointCount(count)
		
	def set_point(self, unsigned int index, point):
		self.p_this.setPoint(index, position_to_vector2f(point))

		
cdef class RectangleShape(Shape):
	cdef dgraphics.RectangleShape *p_this
	
	def __cinit__(self, size=(0, 0)):
		self.p_this = new dgraphics.RectangleShape(size_to_vector2f(size))
		self.p_drawable = <dgraphics.Drawable*>self.p_this
		self.p_transformable = <dgraphics.Transformable*>self.p_this
		self.p_shape = <dgraphics.Shape*>self.p_this
		
	def __dealloc__(self):
		del self.p_this

	property size:
		def __get__(self):
			return Size(self.p_this.getSize().x, self.p_this.getSize().y)
			
		def __set__(self, size):
			self.p_this.setSize(size_to_vector2f(size))


cdef class Vertex:
	cdef dgraphics.Vertex *p_this
	cdef bint              delete_this
	
	def __init__(self, position=None, Color color=None, tex_coords=None):
		self.p_this = new dgraphics.Vertex()
		self.delete_this = True
		
		if position: self.position = position
		if color: self.color = color
		if tex_coords: self.tex_coords = tex_coords
		
	def __dealloc__(self):
		if self.delete_this: del self.p_this
		
	property position:
		def __get__(self):
			return Position(self.p_this.position.x, self.p_this.position.y)
			
		def __set__(self, position):
			self.p_this.position.x, self.p_this.position.y = position
		
	property color:
		def __get__(self):
			cdef dgraphics.Color *p = new dgraphics.Color()
			p[0] = self.p_this.color
			return wrap_color(p)

		def __set__(self, Color color):
			self.p_this.color = color.p_this[0]	

	property tex_coords:
		def __get__(self):
			return Position(self.p_this.texCoords.x, self.p_this.texCoords.y)
			
		def __set__(self, tex_coords):
			self.p_this.texCoords.x, self.p_this.texCoords.y = tex_coords
	
cdef Vertex wrap_vertex(dgraphics.Vertex* p, bint d=True):
	cdef Vertex r = Vertex.__new__(Vertex)
	r.p_this = p
	r.delete_this = d
	return r


cdef class VertexArray(Drawable):
	cdef dgraphics.VertexArray *p_this

	def __init__(self, dgraphics.primitivetype.PrimitiveType type = dgraphics.primitivetype.Points, unsigned int vertex_count=0):
		self.p_this = new dgraphics.VertexArray(type, vertex_count)
		self.p_drawable = <dgraphics.Drawable*>self.p_this
		
	def __dealloc__(self):
		del self.p_this

	def __len__(self):
		return self.p_this.getVertexCount()
		
	def __getitem__(self, unsigned int index):
		if index < len(self):
			return wrap_vertex(&self.p_this[0][index], False)
		else:
			raise IndexError
		
	def __setitem__(self, unsigned int index, Vertex key):
		self.p_this[0][index] = key.p_this[0]
		
	def clear(self):
		self.p_this.clear()
		
	def resize(self, unsigned int vertex_count):
		self.p_this.resize(vertex_count)
		
	def append(self, Vertex vertex):
		self.p_this.append(vertex.p_this[0])
		
	property primitive_type:
		def __get__(self):
			return self.p_this.getPrimitiveType()
			
		def __set__(self, dgraphics.primitivetype.PrimitiveType primitive_type):
			self.p_this.setPrimitiveType(primitive_type)
			
	property bounds:
		def __get__(self):
			cdef dsystem.FloatRect p = self.p_this.getBounds()
			return floatrect_to_rectangle(&p)


cdef class View:
	cdef dgraphics.View  *p_this
	cdef RenderWindow     m_renderwindow
	cdef RenderTarget     m_rendertarget
	
	def __init__(self):
		self.p_this = new dgraphics.View()
		
	def __dealloc__(self):
		del self.p_this
	
	property center:
		def __get__(self):
			return Position(self.p_this.getCenter().x, self.p_this.getCenter().y)
			
		def __set__(self, center):
			self.p_this.setCenter(position_to_vector2f(center))
			self._update_target()

	property size:
		def __get__(self):
			return Size(self.p_this.getSize().x, self.p_this.getSize().y)
			
		def __set__(self, size):
			self.p_this.setSize(size_to_vector2f(size))
			self._update_target()

	property rotation:
		def __get__(self):
			return self.p_this.getRotation()
			
		def __set__(self, float angle):
			self.p_this.setRotation(angle)
			self._update_target()

	property viewport:
		def __get__(self):
			return floatrect_to_rectangle(<dsystem.FloatRect*>(&self.p_this.getViewport()))

		def __set__(self, viewport):
			self.p_this.setViewport(rectangle_to_floatrect(viewport))
			self._update_target()

	def reset(self, rectangle):
		self.p_this.reset(rectangle_to_floatrect(rectangle))
		self._update_target()
	
	def move(self, offset):
		self.p_this.move(position_to_vector2f(offset))
		self._update_target()

	def rotate(self, float angle):
		self.p_this.rotate(angle)
		self._update_target()

	def zoom(self, float factor):
		self.p_this.zoom(factor)
		self._update_target()
	
	property transform:
		def __get__(self):
			cdef dgraphics.Transform *p = new dgraphics.Transform()
			p[0] = self.p_this.getTransform()
			return wrap_transform(p)

	property inverse_transform:
		def __get__(self):
			cdef dgraphics.Transform *p = new dgraphics.Transform()
			p[0] = self.p_this.getInverseTransform()
			return wrap_transform(p)

	def _update_target(self):
		if self.m_renderwindow:
			self.m_renderwindow.view = self

		if self.m_rendertarget:
			self.m_rendertarget.view = self

cdef View wrap_view(dgraphics.View *p):
	cdef View r = View.__new__(View)
	r.p_this = p
	return r
	
cdef View wrap_view_for_renderwindow(dgraphics.View *p, RenderWindow renderwindow):
	cdef View r = View.__new__(View)
	r.p_this = p
	r.m_renderwindow = renderwindow
	return r
	
cdef View wrap_view_for_rendertarget(dgraphics.View *p, RenderTarget rendertarget):
	cdef View r = View.__new__(View)
	r.p_this = p
	r.m_rendertarget = rendertarget
	return r


cdef class RenderTarget:
	cdef dgraphics.RenderTarget *p_rendertarget

	def __init__(self, *args, **kwargs):
		if self.__class__ == RenderTarget:
			raise NotImplementedError('RenderTarget is abstact')

	def clear(self, Color color=None):
		if not color: self.p_rendertarget.clear()
		else: self.p_rendertarget.clear(color.p_this[0])
		
	property view:
		def __get__(self):
			cdef dgraphics.View *p = new dgraphics.View()
			p[0] = self.p_rendertarget.getView()
			return wrap_view_for_rendertarget(p, self)
			
		def __set__(self, View view):
			self.p_rendertarget.setView(view.p_this[0])

	property default_view:
		def __get__(self):
			cdef dgraphics.View *p = new dgraphics.View()
			p[0] = self.p_rendertarget.getDefaultView()
			return wrap_view(p)

	def get_viewport(self, View view):
		cdef dsystem.IntRect p = self.p_rendertarget.getViewport(view.p_this[0])
		return intrect_to_rectangle(&p)
		
	def convert_coords(self, point, View view=None):
		if not view: self.p_rendertarget.convertCoords(position_to_vector2i(point))
		else: self.p_rendertarget.convertCoords(position_to_vector2i(point), view.p_this[0])
			
	def draw(self, Drawable drawable, RenderStates states=None):
		if not states: self.p_rendertarget.draw(drawable.p_drawable[0])
		else: self.p_rendertarget.draw(drawable.p_drawable[0], states.p_this[0])
		
	def draw_vertex(self): pass
		
	property size:
		def __get__(self):
			return Size(self.p_rendertarget.getSize().x, self.p_rendertarget.getSize().y)
		
	property width:
		def __get__(self):
			return self.size.width

	property height:
		def __get__(self):
			return self.size.height

	def push_GL_states(self):
		self.p_rendertarget.pushGLStates()
		
	def pop_GL_states(self):
		self.p_rendertarget.popGLStates()
		
	def reset_GL_states(self):
		self.p_rendertarget.resetGLStates()


cdef api object wrap_rendertarget(dgraphics.RenderTarget* p):
	cdef RenderTarget r = RenderTarget.__new__(RenderTarget)
	r.p_rendertarget = p
	return r


cdef class RenderWindow(Window):
	cdef dgraphics.RenderWindow *p_this
	
	def __init__(self, VideoMode mode, title, Uint32 style=dwindow.style.Default, ContextSettings settings=None):
		cdef char* encoded_title
		
		encoded_title_temporary = title.encode(u"ISO-8859-1")
		encoded_title = encoded_title_temporary
			
		if self.__class__ is not RenderWindow:
			if not settings: self.p_this = new dgraphics.RenderWindow(mode.p_this[0], encoded_title, style)
			else: self.p_this = new dgraphics.RenderWindow(mode.p_this[0], encoded_title, style, settings.p_this[0])
		else:
			if not settings: self.p_this = <dgraphics.RenderWindow*>new dgraphics.DerivableRenderWindow(mode.p_this[0], encoded_title, style)
			else: self.p_this = <dgraphics.RenderWindow*>new dgraphics.DerivableRenderWindow(mode.p_this[0], encoded_title, style, settings.p_this[0])
			
		self.p_window = <dwindow.Window*>self.p_this

	def __dealloc__(self):
		del self.p_this

	def clear(self, Color color=None):
		if not color: self.p_this.clear()
		else: self.p_this.clear(color.p_this[0])
		
	property view:
		def __get__(self):
			cdef dgraphics.View *p = new dgraphics.View()
			p[0] = self.p_this.getView()
			return wrap_view_for_renderwindow(p, self)
			
		def __set__(self, View view):
			self.p_this.setView(view.p_this[0])

	property default_view:
		def __get__(self):
			cdef dgraphics.View *p = new dgraphics.View()
			p[0] = self.p_this.getDefaultView()
			return wrap_view(p)

	def get_viewport(self, View view):
		cdef dsystem.IntRect p = self.p_this.getViewport(view.p_this[0])
		return intrect_to_rectangle(&p)
		
	def convert_coords(self, point, View view=None):
		if not view: self.p_this.convertCoords(position_to_vector2i(point))
		else: self.p_this.convertCoords(position_to_vector2i(point), view.p_this[0])
			
	def draw(self, Drawable drawable, RenderStates states=None):
		if not states: self.p_this.draw(drawable.p_drawable[0])
		else: self.p_this.draw(drawable.p_drawable[0], states.p_this[0])
		
	def draw_vertex(self): pass
		
	property size:
		def __get__(self):
			return Size(self.p_this.getSize().x, self.p_this.getSize().y)
		
	property width:
		def __get__(self):
			return self.size.width

	property height:
		def __get__(self):
			return self.size.height

	def push_GL_states(self):
		self.p_this.pushGLStates()
		
	def pop_GL_states(self):
		self.p_this.popGLStates()
		
	def reset_GL_states(self):
		self.p_this.resetGLStates()

	def capture(self):
		cdef dgraphics.Image *p = new dgraphics.Image()
		p[0] = self.p_this.capture()
		return wrap_image(p)


cdef class RenderTexture(RenderTarget):
	cdef dgraphics.RenderTexture *p_this
	cdef Texture                  m_texture
	
	def __init__(self, unsigned int width, unsigned int height, bint depthBuffer=False):
		self.p_this = new dgraphics.RenderTexture()
		self.p_rendertarget = <dgraphics.RenderTarget*>self.p_this
		
		self.p_this.create(width, height, depthBuffer)
		
	def __dealloc__(self):
		del self.p_this
	
	property smooth:
		def __get__(self):
			return self.p_this.isSmooth()
			
		def __set__(self, bint smooth):
			self.p_this.setSmooth(smooth)
	
	property active:
		def __set__(self, bint active):
			self.p_this.setActive(active)
			
	def display(self):
		self.p_this.display()
	
	property texture:
		def __get__(self):
			self.m_texture.p_this = <dgraphics.Texture*>(&self.p_this.getTexture())
			return self.m_texture

cdef class HandledWindow(RenderTarget):
	cdef dgraphics.RenderWindow *p_this
	cdef dgraphics.Window       *p_window
	
	def __init__(self):
		self.p_this = new dgraphics.RenderWindow()
		self.p_rendertarget = <dgraphics.RenderTarget*>self.p_this
		self.p_window = <dwindow.Window*>self.p_this
		
	def __dealloc__(self):
		del self.p_this

	def create(self, unsigned long window_handle, ContextSettings settings=None):
		if not settings: self.p_this.create(<dwindow.WindowHandle>window_handle)
		else: self.p_this.create(<dwindow.WindowHandle>window_handle, settings.p_this[0])
		
	def display(self):
		self.p_window.display()
