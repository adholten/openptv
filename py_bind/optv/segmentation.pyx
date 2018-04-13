"""
Bindings for image segmentation / target recognition routins in liboptv.

Created on Thu Aug 18 16:22:48 2016

@author: yosef
"""
from libc.stdlib cimport calloc, realloc, free
cimport numpy as np

from optv.parameters cimport TargetParams, ControlParams
from optv.tracking_framebuf cimport TargetArray

def target_recognition(np.ndarray img, TargetParams tpar, int cam, 
    ControlParams cparam, subrange_x=None, subrange_y=None):
    """
    Detects targets (contiguous bright blobs) in an image.
    
    Limited to ~20,000 targets per image for now. This limitation comes from
    the structure of underlying C code.
    
    Arguments:
    np.ndarray img - a numpy array holding the 8-bit gray image.
    TargetParams tpar - target recognition parameters s.a. size bounds etc.
    int cam - number of camera that took the picture, needed for getting
        correct parameters for this image.
    ControlParams cparam - an object holding general control parameters.
    subrange_x - optional, tuple of min and max pixel coordinates to search
        between. Default is to search entire image width.
    subrange_y - optional, tuple of min and max pixel coordinates to search
        between. Default is to search entire image height.
    
    Returns:
    A TargetArray object holding the targets found.
    """
    cdef:
        TargetArray t = TargetArray()
        target *ret
        target *targs = <target *> calloc(1024*20, sizeof(target))
        int num_targs
        int xmin, xmax, ymin, ymax
    
    # Set the subrange (to default if not given):
    if subrange_x is None:
        xmin, xmax = 0, cparam._control_par[0].imx
    else:
        xmin, xmax = subrange_x
    
    if subrange_y is None:
        ymin, ymax = 0, cparam._control_par[0].imy
    else:
        ymin, ymax = subrange_y
    
    # The core liboptv call:
    num_targs = targ_rec(<unsigned char *>img.data, tpar._targ_par, 
        xmin, xmax, ymin, ymax, cparam._control_par, cam, targs)
    
    # Fit the memory size snugly and generate the Python return value.
    ret = <target *>realloc(targs, num_targs * sizeof(target))
    if ret == NULL:
        free(targs)
        raise MemoryError("Failed to reallocate target array.")
    
    t.set(ret, num_targs, 1)
    return t
