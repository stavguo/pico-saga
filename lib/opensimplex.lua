-- opensimplex simple mapgen v2.0
-- 2024 felice, incorporating code by kurt spencer

--------------------------------
-- unlicense: i'll follow the
-- original authors 'unlicense'
-- which basically puts the code
-- in the public domain.
-- see https://gist.github.com/kdotjpg/b1270127455a94ac5d19#file-unlicense
--------------------------------

-- see compute_image() for
-- actual example usage code.

-- opensimplex noise, pico-8 version

------- pico-8 changelog -------
--
-- adapted by felice enellen
-- from public domain code found
-- here:
-- https://gist.github.com/kdotjpg/b1270127455a94ac5d19

-- v2.0
-- - can create multiple noise
--   generators in parallel
-- - can set a bit range for x,y
-- - inlined all foldable const
--   expressions (see "magic
--   numbers" for details)
--
-- v1.2
-- - ported to pico-8 lua
--
------ original changelog ------
--
-- opensimplex noise in java.
-- by kurt spencer
--
-- v1.1 (october 5, 2014)
-- - added 2d and 4d implementations.
-- - proper gradient sets for all dimensions, from a
--   dimensionally-generalizable scheme with an actual
--   rhyme and reason behind it.
-- - removed default permutation array in favor of
--   default seed.
-- - changed seed-based constructor to be independent
--   of any particular randomization library, so results
--   will be the same when ported to other languages.
--
--------------------------------

--------------------------------
-- magic numbers:
--
-- in the code below, you will
-- find some magic numbers with
-- comments next to them that
-- correspond to entries here.
--
-- these numbers have been
-- derived and inlined from
-- constants and foldable
-- expressions in kurt's
-- original code, for the sake
-- of performance.
--
-- sources for the numbers:
--
-- stretch constant:
--  = (1/sqrt(2+1)-1)/2
--  = -0.211324865405187
--
-- squish constant:
--  = (sqrt(2+1)-1)/2
--  = 0.366025403784439
--
-- squish constant + 1
--  = 1.366025403784439
--
-- squish constant * 2
--  = 0.73205080756887729
--
-- squish constant * 2 + 1
--  = 1.73205080756887729
--
-- squish constant * 2 + 2
--  = 2.73205080756887729
--
-- 2d norm constant
--  = ? kurt's code doesn't say
--  = 47
--------------------------------

-- gradients for 2d. they
-- approximate the directions to
-- the vertices of an octagon
-- from the center
local _os2d_grd =
{
    [0] = -- (start at index 0)

        5,
    2,
    2,
    5,
    -5,
    2,
    -2,
    5,
    5,
    -2,
    2,
    -5,
    -5,
    -2,
    -2,
    -5,
}

-- os2d_noisefn()
--
-- initializes a generator using
-- a permutation array generated
-- from a random seed.
--
-- usage:
--
--   -- create two generators
--   noise1=os2d_noise_fn(123)
--   noise2=os2d_noise_fn(456)
--
--   -- get samples from them
--   sample1=noise1(x1,y1)
--   sample2=noise2(x2,y2)
--
--   -- mix and match
--   sample=noise1(x1,y1)*0.67
--         +noise2(x1,y1)*0.33
--
function os2d_noisefn(seed, width)
    -- default to 256x256 area
    width = width or 256
    assert(width >= 1
        and width & (width - 1) == 0,
        "width must be a power of 2")

    -- turn width into a bitmask
    local mask = width - 1

    -- start a new permutation
    local perm = {}

    -- fill with ascending values
    for i = 0, mask do
        perm[i] = i
    end

    -- now create the permutation
    srand(seed)
    for i = mask, 0, -1 do
        -- choose an available index
        local r = flr(rnd(i + 1))
        -- swap into permuted slot
        perm[i], perm[r] = perm[r], perm[i]
    end

    -- finally, return the 2d
    -- opensimplex noise generator
    -- function as a closure with
    -- access to perm[] and mask.
    return function(x, y)
        -- put input coords on grid
        -- the magic number here is
        -- kurt's stretch constant,
        -- 1/sqrt(2+1)-1)/2
        local sto = (x + y) * -0.211324865405187 -- stretch constant
        local xs = x + sto
        local ys = y + sto

        -- flr to get grid
        -- coordinates of rhombus
        -- (stretched square) super-
        -- cell origin.
        local xsb = flr(xs)
        local ysb = flr(ys)

        -- skew out to get actual
        -- coords of rhombus origin.
        -- we'll need these later.
        local sqo = (xsb + ysb) * 0.366025403784439 -- squish constant
        local xb = xsb + sqo
        local yb = ysb + sqo

        -- compute grid coords rel.
        -- to rhombus origin.
        local xins = xs - xsb
        local yins = ys - ysb

        -- sum those together to get
        -- a value that determines
        -- which region we're in.
        local insum = xins + yins

        -- positions relative to
        -- origin point.
        local dx0 = x - xb
        local dy0 = y - yb

        -- we'll be defining these
        -- inside the next block and
        -- using them afterwards.
        local dx_ext, dy_ext, xsv_ext, ysv_ext

        local val = 0

        -- contribution (1,0)
        local dx1 = dx0 - 1.366025403784439 -- squish constant + 1
        local dy1 = dy0 - 0.366025403784439 -- squish constant
        local at1 = 2 - dx1 * dx1 - dy1 * dy1
        if at1 > 0 then
            at1 *= at1
            local i = perm[(perm[(xsb + 1) & mask] + ysb) & mask] & 0x0e
            val += at1 * at1 * (_os2d_grd[i] * dx1 + _os2d_grd[i + 1] * dy1)
        end

        -- contribution (0,1)
        local dx2 = dx0 - 0.366025403784439 -- squish constant
        local dy2 = dy0 - 1.366025403784439 -- squish constant + 1
        local at2 = 2 - dx2 * dx2 - dy2 * dy2
        if at2 > 0 then
            at2 *= at2
            local i = perm[(perm[xsb & mask] + ysb + 1) & mask] & 0x0e
            val += at2 * at2 * (_os2d_grd[i] * dx2 + _os2d_grd[i + 1] * dy2)
        end

        if insum <= 1 then
            -- we're inside the triangle
            -- (2-simplex) at (0,0)
            local zins = 1 - insum
            if zins > xins or zins > yins then
                -- (0,0) is one of the
                -- closest two triangular
                -- vertices
                if xins > yins then
                    xsv_ext = xsb + 1
                    ysv_ext = ysb - 1
                    dx_ext = dx0 - 1
                    dy_ext = dy0 + 1
                else
                    xsv_ext = xsb - 1
                    ysv_ext = ysb + 1
                    dx_ext = dx0 + 1
                    dy_ext = dy0 - 1
                end
            else
                -- (1,0) and (0,1) are the
                -- closest two vertices.
                xsv_ext = xsb + 1
                ysv_ext = ysb + 1
                dx_ext = 1.73205080756887729 -- squish constant * 2 + 1
                dy_ext = 1.73205080756887729 -- squish constant * 2 + 1
            end
        else
            -- we're inside the triangle
            -- (2-simplex) at (1,1)
            local zins = 2 - insum
            if zins < xins or zins < yins then
                -- (0,0) is one of the
                -- closest two triangular
                -- vertices
                if xins > yins then
                    xsv_ext = xsb + 2
                    ysv_ext = ysb
                    dx_ext = dx0 - 2.73205080756887729 -- squish constant * 2 + 2
                    dy_ext = dy0 - 0.73205080756887729 -- squish constant * 2
                else
                    xsv_ext = xsb
                    ysv_ext = ysb + 2
                    dx_ext = dx0 - 0.73205080756887729 -- squish constant * 2
                    dy_ext = dy0 - 2.73205080756887729 -- squish constant * 2 + 2
                end
            else
                -- (1,0) and (0,1) are the
                -- closest two vertices.
                dx_ext = dx0
                dy_ext = dy0
                xsv_ext = xsb
                ysv_ext = ysb
            end
            xsb += 1
            ysb += 1
            dx0 = dx0 - 1.73205080756887729 -- squish constant * 2 + 1
            dy0 = dy0 - 1.73205080756887729 -- squish constant * 2 + 1
        end

        -- contribution (0,0) or (1,1)
        local at0 = 2 - dx0 * dx0 - dy0 * dy0
        if at0 > 0 then
            at0 *= at0
            local i = perm[(perm[xsb & mask] + ysb) & mask] & 0x0e
            val += at0 * at0 * (_os2d_grd[i] * dx0 + _os2d_grd[i + 1] * dy0)
        end

        -- extra vertex
        local atx = 2 - dx_ext * dx_ext - dy_ext * dy_ext
        if atx > 0 then
            atx *= atx
            local i = perm[(perm[xsv_ext & mask] + ysv_ext) & mask] & 0x0e
            val += atx * atx * (_os2d_grd[i] * dx_ext + _os2d_grd[i + 1] * dy_ext)
        end
        return val / 47 -- 2d norm constant
    end
end

-- note kurt's original code had
-- an extrapolate() function
-- here, which was called in
-- four places in eval(), but i
-- found inlining it to produce
-- good performance benefits.
