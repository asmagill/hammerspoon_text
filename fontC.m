#import <Cocoa/Cocoa.h>
// #import <Carbon/Carbon.h>
#import <LuaSkin/LuaSkin.h>
#import "../hammerspoon.h"

// #define USERDATA_TAG        "hs._asm.text.font"
int refTable ;

/// hs._asm.text.font.names() -> table
/// Function
/// Returns the names of all installed fonts for the system.
///
/// Parameters:
///  * None
///
/// Returns:
///  * a table containing the names of every font installed for the system.  The individual names are strings which can be used in the `hs.drawing:setTextFont(fontname)` method.
static int fontNames(lua_State *L) {
    NSArray *fontNames = [[NSFontManager sharedFontManager] availableFonts];

    lua_newtable(L) ;
    for (unsigned long indFont=0; indFont<[fontNames count]; ++indFont)
    {
        lua_pushstring(L, [[fontNames objectAtIndex:indFont] UTF8String]) ; lua_rawseti(L, -2, (lua_Integer)indFont + 1);
    }
    return 1 ;
}

/// hs._asm.text.font.namesWithTraits(fontTraitMask) -> table
/// Function
/// Returns the names of all installed fonts for the system with the specified traits.
///
/// Parameters:
///  * traits - a number, specifying the fontTraitMask, or a table containing traits listed in `hs._asm.text.font.traits` which are logically 'OR'ed together to create the fontTraitMask used.
///
/// Returns:
///  * a table containing the names of every font installed for the system which matches the fontTraitMask specified.  The individual names are strings which can be used in the `hs.drawing:setTextFont(fontname)` method.
///
/// Notes:
///  * specifying 0 or an empty table will match all fonts that are neither italic nor bold.  This would be the same list as you'd get with { hs._asm.text.font.traits.unBold, hs._asm.text.font.traits.unItalic } as the parameter.
static int fontNamesWithTraits(lua_State *L) {
    NSFontTraitMask theTraits = 0 ;

    switch (lua_type(L, 1)) {
        case LUA_TNIL:
        case LUA_TNONE:
            break ;
        case LUA_TNUMBER:
            theTraits = (enum NSFontTraitMask)lua_tointeger(L, 1) ;
            break ;
        case LUA_TTABLE:
            for (lua_pushnil(L); lua_next(L, 1); lua_pop(L, 1)) {
               theTraits |= (enum NSFontTraitMask)lua_tointeger(L, -1) ;
            }
            break ;
        default:
            showError(L, "hs._asm.text.font.namesWithTraits() requires a number or a table as it's parameter");
            lua_pushnil(L);
            return 1;
    }

    NSArray *fontNames = [[NSFontManager sharedFontManager] availableFontNamesWithTraits:theTraits];

    lua_newtable(L) ;
    for (unsigned long indFont=0; indFont<[fontNames count]; ++indFont)
    {
        lua_pushstring(L, [[fontNames objectAtIndex:indFont] UTF8String]) ; lua_rawseti(L, -2, (lua_Integer)indFont + 1);
    }
    return 1 ;
}

/// hs._asm.text.font.traits -> table
/// Constant
/// A table for containing Font Trait masks for use with `hs._asm.text.font.namesWithTraits(...)`
///
///    boldFont                    - fonts with the 'Bold' attribute set
///    compressedFont              - fonts with the 'Compressed' attribute set
///    condensedFont               - fonts with the 'Condensed' attribute set
///    expandedFont                - fonts with the 'Expanded' attribute set
///    fixedPitchFont              - fonts with the 'FixedPitch' attribute set
///    italicFont                  - fonts with the 'Italic' attribute set
///    narrowFont                  - fonts with the 'Narrow' attribute set
///    posterFont                  - fonts with the 'Poster' attribute set
///    smallCapsFont               - fonts with the 'SmallCaps' attribute set
///    nonStandardCharacterSetFont - fonts with the 'NonStandardCharacterSet' attribute set
///    unboldFont                  - fonts that do not have the 'Bold' attribute set
///    unitalicFont                - fonts that do not have the 'Italic' attribute set
static int fontTraits(lua_State* L) {
    lua_newtable(L);
      lua_pushinteger(L, NSBoldFontMask);                    lua_setfield(L, -2, "boldFont");
      lua_pushinteger(L, NSCompressedFontMask);              lua_setfield(L, -2, "compressedFont");
      lua_pushinteger(L, NSCondensedFontMask);               lua_setfield(L, -2, "condensedFont");
      lua_pushinteger(L, NSExpandedFontMask);                lua_setfield(L, -2, "expandedFont");
      lua_pushinteger(L, NSFixedPitchFontMask);              lua_setfield(L, -2, "fixedPitchFont");
      lua_pushinteger(L, NSItalicFontMask);                  lua_setfield(L, -2, "italicFont");
      lua_pushinteger(L, NSNarrowFontMask);                  lua_setfield(L, -2, "narrowFont");
      lua_pushinteger(L, NSPosterFontMask);                  lua_setfield(L, -2, "posterFont");
      lua_pushinteger(L, NSSmallCapsFontMask);               lua_setfield(L, -2, "smallCapsFont");
      lua_pushinteger(L, NSNonStandardCharacterSetFontMask); lua_setfield(L, -2, "nonStandardCharacterSetFont");
      lua_pushinteger(L, NSUnboldFontMask);                  lua_setfield(L, -2, "unboldFont");
      lua_pushinteger(L, NSUnitalicFontMask);                lua_setfield(L, -2, "unitalicFont");
    return 1 ;
}

/// hs._asm.text.font.info(attributesTable) -> table
/// Method
/// Get information about the font Specified in the attributes table.
///
/// Paramters:
///  * None
///
/// Returns:
///  * a table containing the following keys:
///    * fontName           - The font's internally recognized name.
///    * familyName         - The font's family name.
///    * displayName        - The font’s display name is typically localized for the user’s language.
///    * fixedPitch         - A boolean value indicating whether all glyphs in the font have the same advancement.
///    * ascender           - The top y-coordinate, offset from the baseline, of the font’s longest ascender.
///    * boundingRect       - A table containing the font’s bounding rectangle, scaled to the font’s size.  This rectangle is the union of the bounding rectangles of every glyph in the font.
///    * capHeight          - The cap height of the font.
///    * descender          - The bottom y-coordinate, offset from the baseline, of the font’s longest descender.
///    * italicAngle        - The number of degrees that the font is slanted counterclockwise from the vertical. (read-only)
///    * leading            - The leading value of the font.
///    * maximumAdvancement - A table containing the maximum advance of any of the font’s glyphs.
///    * numberOfGlyphs     - The number of glyphs in the font.
///    * pointSize          - The point size of the font.
///    * underlinePosition  - The baseline offset to use when drawing underlines with the font.
///    * underlineThickness - The thickness to use when drawing underlines with the font.
///    * xHeight            - The x-height of the font.
///
/// Notes:
///  * the only fields required in the attributes table are `font` and `size` which contain the font name and font size respectively.
static int fontInformation(lua_State *L) {
    NSFont *theFont = [[LuaSkin shared] tableAtIndex:-1 toClass:"NSFont"] ;

    lua_newtable(L) ;
        [[LuaSkin shared] pushNSObject:[theFont fontName]] ;    lua_setfield(L, -2, "fontName") ;
        [[LuaSkin shared] pushNSObject:[theFont familyName]] ;  lua_setfield(L, -2, "familyName") ;
        [[LuaSkin shared] pushNSObject:[theFont displayName]] ; lua_setfield(L, -2, "displayName") ;
        lua_pushboolean(L, [theFont isFixedPitch]) ;            lua_setfield(L, -2, "fixedPitch") ;
        lua_pushnumber(L, [theFont ascender]) ;                 lua_setfield(L, -2, "ascender") ;
        NSRect boundingRect = [theFont boundingRectForFont] ;
        lua_newtable(L) ;
          lua_pushnumber(L, boundingRect.origin.x) ;    lua_setfield(L, -2, "x") ;
          lua_pushnumber(L, boundingRect.origin.y) ;    lua_setfield(L, -2, "y") ;
          lua_pushnumber(L, boundingRect.size.height) ; lua_setfield(L, -2, "h") ;
          lua_pushnumber(L, boundingRect.size.width) ;  lua_setfield(L, -2, "w") ;
        lua_setfield(L, -2, "boundingRect") ;
        lua_pushnumber(L, [theFont capHeight]) ;                lua_setfield(L, -2, "capHeight") ;
        lua_pushnumber(L, [theFont descender]) ;                lua_setfield(L, -2, "descender") ;
        lua_pushnumber(L, [theFont italicAngle]) ;              lua_setfield(L, -2, "italicAngle") ;
        lua_pushnumber(L, [theFont leading]) ;                  lua_setfield(L, -2, "leading") ;
        NSSize maxAdvance = [theFont maximumAdvancement] ;
        lua_newtable(L) ;
          lua_pushnumber(L, maxAdvance.height) ; lua_setfield(L, -2, "h") ;
          lua_pushnumber(L, maxAdvance.width) ; lua_setfield(L, -2, "w") ;
        lua_setfield(L, -2, "maximumAdvancement") ;
        lua_pushinteger(L, (lua_Integer)[theFont numberOfGlyphs]) ;          lua_setfield(L, -2, "numberOfGlyphs") ;
        lua_pushnumber(L, [theFont pointSize]) ;                lua_setfield(L, -2, "pointSize") ;
        lua_pushnumber(L, [theFont underlinePosition]) ;        lua_setfield(L, -2, "underlinePosition") ;
        lua_pushnumber(L, [theFont underlineThickness]) ;       lua_setfield(L, -2, "underlineThickness") ;
        lua_pushnumber(L, [theFont xHeight]) ;                  lua_setfield(L, -2, "xHeight") ;
    return 1 ;
}

static int NSFont_tolua(lua_State *L, id obj) {
    NSFont *theFont = obj ;

    lua_newtable(L) ;
        [[LuaSkin shared] pushNSObject:[theFont fontName]] ;    lua_setfield(L, -2, "font") ;
        lua_pushnumber(L, [theFont pointSize]) ;                lua_setfield(L, -2, "size") ;

    return 1 ;
}

static id table_toNSFont(lua_State* L, int idx) {
    NSString *theName = [[NSFont systemFontOfSize:0] fontName] ;
    CGFloat  theSize = [NSFont systemFontSize] ;

    lua_pushvalue(L, idx) ;
    switch (lua_type(L, idx)) {
        case LUA_TTABLE:
            if (lua_getfield(L, -1, "font") == LUA_TSTRING)
                theName = [NSString stringWithUTF8String:luaL_checkstring(L, -1)] ;
            lua_pop(L, 1);

            if (lua_getfield(L, -1, "size") == LUA_TNUMBER)
                theSize = lua_tonumber(L, -1);
            lua_pop(L, 1);

            break;

        default:
            luaL_error(L, [[NSString stringWithFormat:@"Unexpected type passed as a NSFont: %s", lua_typename(L, lua_type(L, idx))] UTF8String]) ;
            return nil ;
            break;
    }

    lua_pop(L, 1);
    return [NSFont fontWithName:theName size:theSize] ;
}

// static int userdata_tostring(lua_State* L) {
//     return 1 ;
// }

// static int userdata_eq(lua_State* L) {
//     return 1 ;
// }

// static int userdata_gc(lua_State* L) {
//     return 0 ;
// }

// static int meta_gc(lua_State* __unused L) {
//     [hsimageReferences removeAllIndexes];
//     hsimageReferences = nil;
//     return 0 ;
// }

// Metatable for userdata objects
// static const luaL_Reg userdata_metaLib[] = {
//     {"__tostring",  userdata_tostring},
//     {"__eq",        userdata_eq},
//     {"__gc",        userdata_gc},
//     {NULL,          NULL}
// };

// Functions for returned object when module loads
static luaL_Reg moduleLib[] = {
    {"info",            fontInformation},
    {"names",           fontNames},
    {"namesWithTraits", fontNamesWithTraits},
    {NULL,              NULL}
};

// // Metatable for module, if needed
// static const luaL_Reg module_metaLib[] = {
//     {"__gc", meta_gc},
//     {NULL,   NULL}
// };

// NOTE: ** Make sure to change luaopen_..._internal **
int luaopen_hs__asm_text_fontC(lua_State* L) {
    LuaSkin *skin = [LuaSkin shared];
    refTable = [skin registerLibrary:moduleLib metaFunctions:nil] ; // or module_metaLib

    fontTraits(L) ; lua_setfield(L, -2, "traits") ;

    [skin registerPushNSHelper:NSFont_tolua forClass:"NSFont"] ;
    [skin registerTableHelper:table_toNSFont forClass:"NSFont"] ;

    return 1;
}
