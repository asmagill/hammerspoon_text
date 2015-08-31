#import <Cocoa/Cocoa.h>
// #import <Carbon/Carbon.h>
#import <LuaSkin/LuaSkin.h>
#import "../hammerspoon.h"

// Note:  The following is organized to maintain compatibility with the existing methods and
// table organization structure for text styles as used in hs.drawing.  A more proper
// treatment would be to treat the table these methods work with as the actual NSDictionary
// used for the NSAttributedString type.  The differences would include:
//    lineBreak would be named lineBreakMode
//    the NSParagraphStyle fields would be grouped in a table, not mixed with the attribute
//        dictionary keys
//    dictionary keys would probably be their actual names: NS<key>AttributeName, or at least
//        the NSString those resolve to
//    the NSParagraphStyle lineBreakMode, alignment, and baseWritingDirection would be int with
//        lookup tables and not strings
//    the font and size keys would be fontName and pointSize and would be in a separate table
//        as the NSFontAttributeName entry, rather than mixed like NSParagraphStyle's keys
//    color would be foregroundColor
//    probably a few other names would change as well to more closely match their obj-c names
//
// But as a proof of concept for the LuaSkin conversion methods, I have to say I'm pretty happy
// with it.
//
// Todo:  [ ] proper tab support (probably - I want to be able to format shell output on the display)
//        [ ] suppress unrecognized/unsupported keys (headerLevel in NSParagraphStyle comes to mind).
//            right now everything found is included to make sure I haven't missed or misspelled anything.
//        [ ] allow full NSAttributedString support -- meaning multiple dictionaries for differing
//            ranges.  (probably not... would rather see a WebView treatment if we decide we want
//            that level of control.)

// #define USERDATA_TAG        "hs._asm.text.attributes"
int refTable ;

/// hs._asm.text.attributes.lineStyles
/// Constant
/// A table of styles which apply to the line for underlining or strike-through.
///
/// Notes:
///  * When specifying a line type for underlining or strike-through, you can combine one entry from each of the following tables:
///    * hs._asm.text.attributes.lineStyles
///    * hs._asm.text.attributes.linePatterns
///    * hs._asm.text.attributes.lineAppliesTo
///  * The entries chosen should be combined with the `or` operator to provide a single value. for example:
///    * hs._asm.text.attributes.lineStyles.single | hs._asm.text.attributes.linePatterns.dash | hs._asm.text.attributes.lineAppliesToWord
static int defineLineStyles(lua_State *L) {
    lua_newtable(L) ;
      lua_pushinteger(L, NSUnderlineStyleNone) ;    lua_setfield(L, -2, "none") ;
      lua_pushinteger(L, NSUnderlineStyleSingle) ;  lua_setfield(L, -2, "single") ;
      lua_pushinteger(L, NSUnderlineStyleThick) ;   lua_setfield(L, -2, "thick") ;
      lua_pushinteger(L, NSUnderlineStyleDouble) ;  lua_setfield(L, -2, "double") ;
    return 1 ;
}

/// hs._asm.text.attributes.linePatterns
/// Constant
/// A table of patterns which apply to the line for underlining or strike-through.
///
/// Notes:
///  * When specifying a line type for underlining or strike-through, you can combine one entry from each of the following tables:
///    * hs._asm.text.attributes.lineStyles
///    * hs._asm.text.attributes.linePatterns
///    * hs._asm.text.attributes.lineAppliesTo
///  * The entries chosen should be combined with the `or` operator to provide a single value. for example:
///    * hs._asm.text.attributes.lineStyles.single | hs._asm.text.attributes.linePatterns.dash | hs._asm.text.attributes.lineAppliesToWord
static int defineLinePatterns(lua_State *L) {
    lua_newtable(L) ;
      lua_pushinteger(L, NSUnderlinePatternSolid) ;       lua_setfield(L, -2, "solid") ;
      lua_pushinteger(L, NSUnderlinePatternDot) ;         lua_setfield(L, -2, "dot") ;
      lua_pushinteger(L, NSUnderlinePatternDash) ;        lua_setfield(L, -2, "dash") ;
      lua_pushinteger(L, NSUnderlinePatternDashDot) ;     lua_setfield(L, -2, "dashDot") ;
      lua_pushinteger(L, NSUnderlinePatternDashDotDot) ;  lua_setfield(L, -2, "dashDotDot") ;
    return 1 ;
}

/// hs._asm.text.attributes.lineAppliesTo
/// Constant
/// A table of values indicating how the line for underlining or strike-through are applied to the text.
///
/// Notes:
///  * When specifying a line type for underlining or strike-through, you can combine one entry from each of the following tables:
///    * hs._asm.text.attributes.lineStyles
///    * hs._asm.text.attributes.linePatterns
///    * hs._asm.text.attributes.lineAppliesTo
///  * The entries chosen should be combined with the `or` operator to provide a single value. for example:
///    * hs._asm.text.attributes.lineStyles.single | hs._asm.text.attributes.linePatterns.dash | hs._asm.text.attributes.lineAppliesToWord
static int defineLineAppliesTo(lua_State *L) {
    lua_newtable(L) ;
      lua_pushinteger(L, 0) ;                                  lua_setfield(L, -2, "line") ;
      lua_pushinteger(L, (lua_Integer)NSUnderlineByWordMask) ; lua_setfield(L, -2, "word") ;
    return 1 ;
}

static int NSAttributedString_tolua(lua_State *L, id obj) {
    NSAttributedString *theString = obj ;

    lua_newtable(L) ;
// NSLog(@"%@", [theString string]) ;
      lua_pushstring(L, [[theString string] UTF8String]) ;
      lua_seti(L, -2, 1) ;

      lua_newtable(L) ; int destTableIndex = lua_absindex(L, -1) ;
        // Get attributes
        NSMutableDictionary     *attributes ;
        @try {
            attributes = [[theString attributesAtIndex:0 effectiveRange:nil] mutableCopy] ;
        }
        @catch ( NSException *theException ) {
            attributes = [@{NSParagraphStyleAttributeName:[NSParagraphStyle defaultParagraphStyle]} mutableCopy] ;
        }
        for (id key in attributes) {
            [[LuaSkin shared] pushNSObject:[attributes objectForKey:key]] ;

// NSLog(@"%@ : %@", key, [attributes objectForKey:key]) ;
            if ([(NSString *)key isEqualToString:NSFontAttributeName]) {
                if (lua_type(L, -1) == LUA_TTABLE) {
                    int tableIdx = lua_absindex(L, -1) ;
                    lua_pushnil(L);  /* first key */
                    while (lua_next(L, tableIdx)) {
                        // -2 = key
                        // -1 = value
                        const char *keyName = lua_tostring(L, -2) ;
                        lua_setfield(L, destTableIndex, keyName) ;
                    }
                } else {
                    lua_pushstring(L, "unable to get font name") ;
                    lua_setfield(L, destTableIndex, "fontError") ;
                }
                lua_pop(L, 1) ;
            } else if ([(NSString *)key isEqualToString:NSUnderlineStyleAttributeName]) {
                lua_setfield(L, destTableIndex, "underlineStyle") ;
            } else if ([(NSString *)key isEqualToString:NSSuperscriptAttributeName]) {
                lua_setfield(L, destTableIndex, "superscript") ;
            } else if ([(NSString *)key isEqualToString:NSLigatureAttributeName]) {
                lua_setfield(L, destTableIndex, "ligature") ;
            } else if ([(NSString *)key isEqualToString:NSBaselineOffsetAttributeName]) {
                lua_setfield(L, destTableIndex, "baselineOffset") ;
            } else if ([(NSString *)key isEqualToString:NSKernAttributeName]) {
                lua_setfield(L, destTableIndex, "kerning") ;
            } else if ([(NSString *)key isEqualToString:NSStrokeWidthAttributeName]) {
                lua_setfield(L, destTableIndex, "strokeWidth") ;
            } else if ([(NSString *)key isEqualToString:NSStrikethroughStyleAttributeName]) {
                lua_setfield(L, destTableIndex, "strikethroughStyle") ;
            } else if ([(NSString *)key isEqualToString:NSObliquenessAttributeName]) {
                lua_setfield(L, destTableIndex, "obliqueness") ;
            } else if ([(NSString *)key isEqualToString:NSExpansionAttributeName]) {
                lua_setfield(L, destTableIndex, "expansion") ;
            } else if ([(NSString *)key isEqualToString:NSLinkAttributeName]) {
                lua_setfield(L, destTableIndex, "link") ;
            } else if ([(NSString *)key isEqualToString:NSToolTipAttributeName]) {
                lua_setfield(L, destTableIndex, "tooltip") ;
            } else if ([(NSString *)key isEqualToString:NSForegroundColorAttributeName]) {
                lua_setfield(L, destTableIndex, "color") ;
            } else if ([(NSString *)key isEqualToString:NSBackgroundColorAttributeName]) {
                lua_setfield(L, destTableIndex, "backgroundColor") ;
            } else if ([(NSString *)key isEqualToString:NSStrokeColorAttributeName]) {
                lua_setfield(L, destTableIndex, "strokeColor") ;
            } else if ([(NSString *)key isEqualToString:NSUnderlineColorAttributeName]) {
                lua_setfield(L, destTableIndex, "underlineColor") ;
            } else if ([(NSString *)key isEqualToString:NSStrikethroughColorAttributeName]) {
                lua_setfield(L, destTableIndex, "strikethroughColor") ;
            } else if ([(NSString *)key isEqualToString:NSShadowAttributeName]) {
                lua_setfield(L, destTableIndex, "shadow") ;
            } else if ([(NSString *)key isEqualToString:NSParagraphStyleAttributeName]) {
                if (lua_type(L, -1) == LUA_TTABLE) {
                    int tableIdx = lua_absindex(L, -1) ;
                    lua_pushnil(L);  /* first key */
                    while (lua_next(L, tableIdx)) {
                        // -2 = key
                        // -1 = value
                        const char *keyName = lua_tostring(L, -2) ;
                        lua_setfield(L, destTableIndex, keyName) ;
                    }
                } else {
                    lua_pushstring(L, "unable to get paragraph style") ;
                    lua_setfield(L, destTableIndex, "paragraphStyleError") ;
                }
                lua_pop(L, 1) ;
            } else {
                lua_setfield(L, destTableIndex, [(NSString *)key UTF8String]) ;
            }
        }
      lua_seti(L, -2, 2) ;
    return 1 ;
}

static id table_toNSAttributedString(lua_State* L, int idx) {
    lua_geti(L, idx, 1) ;
    NSString *theString = [NSString stringWithUTF8String:luaL_checkstring(L, -1)] ;
    lua_pop(L, 1) ; // the string on the stack
    lua_geti(L, idx, 2) ;
    luaL_checktype(L, -1, LUA_TTABLE) ;
    NSMutableDictionary *theAttributes = [[NSMutableDictionary alloc] init] ;

    [theAttributes setObject:[[LuaSkin shared] tableAtIndex:-1 toClass:"NSFont"]
                      forKey:NSFontAttributeName] ;
    [theAttributes setObject:[[LuaSkin shared] tableAtIndex:-1 toClass:"NSParagraphStyle"]
                      forKey:NSParagraphStyleAttributeName] ;

    if (lua_getfield(L, -1, "underlineStyle") == LUA_TNUMBER)
        [theAttributes setObject:@(lua_tointeger(L, -1)) forKey:NSUnderlineStyleAttributeName] ;
    lua_pop(L, 1);
    if (lua_getfield(L, -1, "superscript") == LUA_TNUMBER)
        [theAttributes setObject:@(lua_tointeger(L, -1)) forKey:NSSuperscriptAttributeName] ;
    lua_pop(L, 1);
    if (lua_getfield(L, -1, "ligature") == LUA_TNUMBER)
        [theAttributes setObject:@(lua_tointeger(L, -1)) forKey:NSLigatureAttributeName] ;
    lua_pop(L, 1);
    if (lua_getfield(L, -1, "strikethroughStyle") == LUA_TNUMBER)
        [theAttributes setObject:@(lua_tointeger(L, -1)) forKey:NSStrikethroughStyleAttributeName] ;
    lua_pop(L, 1);
    if (lua_getfield(L, -1, "baselineOffset") == LUA_TNUMBER)
        [theAttributes setObject:@(lua_tonumber(L, -1)) forKey:NSBaselineOffsetAttributeName] ;
    lua_pop(L, 1);
    if (lua_getfield(L, -1, "kerning") == LUA_TNUMBER)
        [theAttributes setObject:@(lua_tonumber(L, -1)) forKey:NSKernAttributeName] ;
    lua_pop(L, 1);
    if (lua_getfield(L, -1, "strokeWidth") == LUA_TNUMBER)
        [theAttributes setObject:@(lua_tonumber(L, -1)) forKey:NSStrokeWidthAttributeName] ;
    lua_pop(L, 1);
    if (lua_getfield(L, -1, "obliqueness") == LUA_TNUMBER)
        [theAttributes setObject:@(lua_tonumber(L, -1)) forKey:NSObliquenessAttributeName] ;
    lua_pop(L, 1);
    if (lua_getfield(L, -1, "expansion") == LUA_TNUMBER)
        [theAttributes setObject:@(lua_tonumber(L, -1)) forKey:NSExpansionAttributeName] ;
    lua_pop(L, 1);

    if (lua_getfield(L, -1, "color") == LUA_TTABLE)
        [theAttributes setObject:[[LuaSkin shared] tableAtIndex:-1 toClass:"NSColor"] forKey:NSForegroundColorAttributeName] ;
    lua_pop(L, 1);
    if (lua_getfield(L, -1, "backgroundColor") == LUA_TTABLE)
        [theAttributes setObject:[[LuaSkin shared] tableAtIndex:-1 toClass:"NSColor"] forKey:NSBackgroundColorAttributeName] ;
    lua_pop(L, 1);
    if (lua_getfield(L, -1, "strokeColor") == LUA_TTABLE)
        [theAttributes setObject:[[LuaSkin shared] tableAtIndex:-1 toClass:"NSColor"] forKey:NSStrokeColorAttributeName] ;
    lua_pop(L, 1);
    if (lua_getfield(L, -1, "underlineColor") == LUA_TTABLE)
        [theAttributes setObject:[[LuaSkin shared] tableAtIndex:-1 toClass:"NSColor"] forKey:NSUnderlineColorAttributeName] ;
    lua_pop(L, 1);
    if (lua_getfield(L, -1, "strikethroughColor") == LUA_TTABLE)
        [theAttributes setObject:[[LuaSkin shared] tableAtIndex:-1 toClass:"NSColor"] forKey:NSStrikethroughColorAttributeName] ;
    lua_pop(L, 1);
    if (lua_getfield(L, -1, "shadow") == LUA_TTABLE)
        [theAttributes setObject:[[LuaSkin shared] tableAtIndex:-1 toClass:"NSShadow"] forKey:NSShadowAttributeName] ;
    lua_pop(L, 1);

    lua_pop(L, 1); // the attributes table on the stack
    return [[NSAttributedString alloc] initWithString:theString attributes:theAttributes] ;
}

// static int userdata_tostring(lua_State* L) {
// }

// static int userdata_eq(lua_State* L) {
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
//     {"__tostring", userdata_tostring},
//     {"__eq",       userdata_eq},
//     {"__gc",       userdata_gc},
//     {NULL,         NULL}
// };

// Functions for returned object when module loads
static luaL_Reg moduleLib[] = {
    {NULL, NULL}
};

// // Metatable for module, if needed
// static const luaL_Reg module_metaLib[] = {
//     {"__gc", meta_gc},
//     {NULL,   NULL}
// };

// NOTE: ** Make sure to change luaopen_..._internal **
int luaopen_hs__asm_text_attributesC(lua_State* L) {
    LuaSkin *skin = [LuaSkin shared];
    refTable = [skin registerLibrary:moduleLib metaFunctions:nil] ;
//     refTable = [skin registerLibraryWithObject:USERDATA_TAG
//                                      functions:moduleLib
//                                  metaFunctions:nil    // or module_metaLib
//                                objectFunctions:nil ]; // or userdata_metaLib

    defineLinePatterns(L) ;  lua_setfield(L, -2, "linePatterns") ;
    defineLineStyles(L) ;    lua_setfield(L, -2, "lineStyles") ;
    defineLineAppliesTo(L) ; lua_setfield(L, -2, "lineAppliesTo") ;

    [skin registerPushNSHelper:NSAttributedString_tolua forClass:"NSAttributedString"] ;
    [skin registerTableHelper:table_toNSAttributedString forClass:"NSAttributedString"] ;

    return 1;
}
