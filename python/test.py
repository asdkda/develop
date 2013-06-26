pyver = (2, 5)
pygtkver = (2, 14, 0)
pygobjectver = (2, 16, 0)


# gtk+ and related imports
try:
    import pygtk
    print "pygtk in"
    pygtk.require("2.0")
except (ImportError, AssertionError), e:
    print e
    missing_reqs("pygtk", pygtkver, e)

try:
    import gtk
    print "gtk in"
    print gtk.pygtk_version
    assert gtk.pygtk_version >= pygtkver
except (ImportError, AssertionError), e:
    print e
    missing_reqs("pygtk", pygtkver, e)

try:
    import gobject
    print "gobject in"
    print gobject.pygobject_version
    assert gobject.pygobject_version >= pygobjectver
except (ImportError, AssertionError), e:
    print e
    missing_reqs("pygobject", pygobjectver, e)

print "IN"
