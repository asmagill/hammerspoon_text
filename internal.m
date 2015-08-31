#import <Cocoa/Cocoa.h>
// #import <Carbon/Carbon.h>
#import <LuaSkin/LuaSkin.h>
#import "../hammerspoon.h"

// #define USERDATA_TAG        "hs._asm.text"
int refTable ;

// #define get_objectFromUserdata(objType, L, idx) (__bridge objType*)*((void**)luaL_checkudata(L, idx, USERDATA_TAG))
// #define get_structFromUserdata(objType, L, idx) ((objType *)luaL_checkudata(L, idx, USERDATA_TAG))

typedef struct _drawing_t {
    void *window;
} drawing_t;

@interface HSDrawingWindow : NSWindow <NSWindowDelegate>
@end

@interface HSDrawingView : NSView {
    lua_State *L;
}
@property int mouseUpCallbackRef;
@property int mouseDownCallbackRef;
@property BOOL HSFill;
@property BOOL HSStroke;
@property CGFloat HSLineWidth;
@property (nonatomic, strong) NSColor *HSFillColor;
@property (nonatomic, strong) NSColor *HSGradientStartColor;
@property (nonatomic, strong) NSColor *HSGradientEndColor;
@property int HSGradientAngle;
@property (nonatomic, strong) NSColor *HSStrokeColor;
@property CGFloat HSRoundedRectXRadius;
@property CGFloat HSRoundedRectYRadius;
@end

@interface HSDrawingViewText : HSDrawingView
@property (nonatomic, strong) NSTextField *textField;
@end

static int NSShadow_tolua(lua_State *L, id obj) {
    NSShadow *theShadow = obj ;
    NSSize   offset = [theShadow shadowOffset] ;

    lua_newtable(L) ;
        lua_newtable(L) ;
            lua_pushnumber(L, offset.height) ; lua_setfield(L, -2, "h") ;
            lua_pushnumber(L, offset.width) ;  lua_setfield(L, -2, "w") ;
        lua_setfield(L, -2, "offset") ;
        lua_pushnumber(L, [theShadow shadowBlurRadius]) ; lua_setfield(L, -2, "blurRadius") ;
        [[LuaSkin shared] pushNSObject:[theShadow shadowColor]] ; lua_setfield(L, -2, "color") ;

    return 1 ;
}

static id table_toNSShadow(lua_State* L, int idx) {
    NSShadow *theShadow = [[NSShadow alloc] init] ;

    lua_pushvalue(L, idx) ;
    switch (lua_type(L, idx)) {
        case LUA_TTABLE:
            if (lua_getfield(L, -1, "offset") == LUA_TTABLE) {
                NSSize offset ;
                lua_getfield(L, -1, "h") ; offset.height = luaL_checknumber(L, -1) ; lua_pop(L, 1) ;
                lua_getfield(L, -1, "w") ; offset.width = luaL_checknumber(L, -1) ; lua_pop(L, 1) ;
                [theShadow setShadowOffset:offset] ;
            }
            lua_pop(L, 1);

            if (lua_getfield(L, -1, "blurRadius") == LUA_TNUMBER)
                [theShadow setShadowBlurRadius:luaL_checknumber(L, -1)] ;
            lua_pop(L, 1);

            if (lua_getfield(L, -1, "color") == LUA_TTABLE)
                [theShadow setShadowColor:[[LuaSkin shared] tableAtIndex:-1 toClass:"NSColor"]] ;
            lua_pop(L, 1);

            break;

        default:
            luaL_error(L, [[NSString stringWithFormat:@"Unexpected type passed as a NSShadow: %s", lua_typename(L, lua_type(L, idx))] UTF8String]) ;
            return nil ;
            break;
    }

    lua_pop(L, 1);
    return theShadow ;
}

static int NSColor_tolua(lua_State *L, id obj) {
    NSColor *theColor = obj ;
    NSColor *safeColor = [theColor colorUsingColorSpaceName:NSCalibratedRGBColorSpace] ;

    lua_newtable(L) ;
    if (safeColor) {
        lua_pushnumber(L, [safeColor redComponent])   ; lua_setfield(L, -2, "red") ;
        lua_pushnumber(L, [safeColor greenComponent]) ; lua_setfield(L, -2, "green") ;
        lua_pushnumber(L, [safeColor blueComponent])  ; lua_setfield(L, -2, "blue") ;
        lua_pushnumber(L, [safeColor alphaComponent]) ; lua_setfield(L, -2, "alpha") ;
    } else {
        lua_pushstring(L, [[NSString stringWithFormat:@"unable to convert colorspace from %@ to NSCalibratedRGBColorSpace", [theColor colorSpaceName]] UTF8String]) ;
    }

    return 1 ;
}

static id table_toNSColor(lua_State *L, int idx) {
    CGFloat red = 0.0, green = 0.0, blue = 0.0, alpha = 1.0 ;

    lua_pushvalue(L, idx) ;
    switch (lua_type(L, idx)) {
        case LUA_TTABLE:
            if (lua_getfield(L, -1, "red") == LUA_TNUMBER)
                red = lua_tonumber(L, -1);
            lua_pop(L, 1);

            if (lua_getfield(L, -1, "green") == LUA_TNUMBER)
                green = lua_tonumber(L, -1);
            lua_pop(L, 1);

            if (lua_getfield(L, -1, "blue") == LUA_TNUMBER)
                blue = lua_tonumber(L, -1);
            lua_pop(L, 1);

            if (lua_getfield(L, -1, "alpha") == LUA_TNUMBER)
                alpha = lua_tonumber(L, -1);
            lua_pop(L, 1);

            break;
        default:
            luaL_error(L, [[NSString stringWithFormat:@"Unexpected type passed as a color: %s", lua_typename(L, lua_type(L, idx))] UTF8String]) ;
            return nil ;
            break;
    }

    lua_pop(L, 1);
    return [NSColor colorWithSRGBRed:red green:green blue:blue alpha:alpha];
}

static int NSParagraphStyle_tolua(lua_State *L, id obj) {
    NSParagraphStyle *thePS = obj ;

    lua_newtable(L) ;

    if ([thePS alignment] == NSLeftTextAlignment)      { lua_pushstring(L, "left") ; } else
    if ([thePS alignment] == NSRightTextAlignment)     { lua_pushstring(L, "right") ; } else
    if ([thePS alignment] == NSCenterTextAlignment)    { lua_pushstring(L, "center") ; } else
    if ([thePS alignment] == NSJustifiedTextAlignment) { lua_pushstring(L, "justified") ; } else
    if ([thePS alignment] == NSNaturalTextAlignment)   { lua_pushstring(L, "natural") ; }
    else { lua_pushstring(L, "unknown") ; }
    lua_setfield(L, -2, "alignment") ;

    if ([thePS lineBreakMode] == NSLineBreakByWordWrapping)     { lua_pushstring(L, "wordWrap") ;       } else
    if ([thePS lineBreakMode] == NSLineBreakByCharWrapping)     { lua_pushstring(L, "charWrap") ;       } else
    if ([thePS lineBreakMode] == NSLineBreakByClipping)         { lua_pushstring(L, "clip") ;           } else
    if ([thePS lineBreakMode] == NSLineBreakByTruncatingHead)   { lua_pushstring(L, "truncateHead") ;   } else
    if ([thePS lineBreakMode] == NSLineBreakByTruncatingTail)   { lua_pushstring(L, "truncateTail") ;   } else
    if ([thePS lineBreakMode] == NSLineBreakByTruncatingMiddle) { lua_pushstring(L, "truncateMiddle") ; }
    else { lua_pushstring(L, "unknown") ; }
    lua_setfield(L, -2, "lineBreak") ;

    if ([thePS baseWritingDirection] == NSWritingDirectionNatural)     { lua_pushstring(L, "natural") ;     } else
    if ([thePS baseWritingDirection] == NSWritingDirectionLeftToRight) { lua_pushstring(L, "leftToRight") ; } else
    if ([thePS baseWritingDirection] == NSWritingDirectionRightToLeft) { lua_pushstring(L, "rightToLeft") ; }
    else { lua_pushstring(L, "unknown") ; }
    lua_setfield(L, -2, "baseWritingDirection") ;

    // we grossly simplify tab stops for now... maybe if we add an actual editable text document item
    // it'll be worth the effort, but for now, I'm ignoring it.
    lua_pushnumber(L, [thePS defaultTabInterval]) ;             lua_setfield(L, -2, "defaultTabInterval") ;

    lua_pushnumber(L, [thePS firstLineHeadIndent]) ;            lua_setfield(L, -2, "firstLineHeadIndent") ;
    lua_pushnumber(L, [thePS headIndent]) ;                     lua_setfield(L, -2, "headIndent") ;
    lua_pushnumber(L, [thePS tailIndent]) ;                     lua_setfield(L, -2, "tailIndent") ;
    lua_pushnumber(L, [thePS maximumLineHeight]) ;              lua_setfield(L, -2, "maximumLineHeight") ;
    lua_pushnumber(L, [thePS minimumLineHeight]) ;              lua_setfield(L, -2, "minimumLineHeight") ;
    lua_pushnumber(L, [thePS lineSpacing]) ;                    lua_setfield(L, -2, "lineSpacing") ;
    lua_pushnumber(L, [thePS paragraphSpacing]) ;               lua_setfield(L, -2, "paragraphSpacing") ;
    lua_pushnumber(L, [thePS paragraphSpacingBefore]) ;         lua_setfield(L, -2, "paragraphSpacingBefore") ;
    lua_pushnumber(L, [thePS lineHeightMultiple]) ;             lua_setfield(L, -2, "lineHeightMultiple") ;
    lua_pushnumber(L, [thePS hyphenationFactor]) ;              lua_setfield(L, -2, "hyphenationFactor") ;
    lua_pushnumber(L, [thePS tighteningFactorForTruncation]) ;  lua_setfield(L, -2, "tighteningFactorForTruncation") ;

    return 1 ;
}

static id table_toNSParagraphStyle(lua_State* L, int idx) {
    NSMutableParagraphStyle *thePS = [[NSParagraphStyle defaultParagraphStyle] mutableCopy] ;

    lua_pushvalue(L, idx) ;
    switch (lua_type(L, idx)) {
        case LUA_TTABLE:
            if (lua_getfield(L, -1, "alignment") == LUA_TSTRING) {
                NSString *theString = [NSString stringWithUTF8String:luaL_checkstring(L, -1)];
                if ([theString isEqualToString:@"left"])      { thePS.alignment = NSLeftTextAlignment ;      } else
                if ([theString isEqualToString:@"right"])     { thePS.alignment = NSRightTextAlignment ;     } else
                if ([theString isEqualToString:@"center"])    { thePS.alignment = NSCenterTextAlignment ;    } else
                if ([theString isEqualToString:@"justified"]) { thePS.alignment = NSJustifiedTextAlignment ; } else
                if ([theString isEqualToString:@"natural"])   { thePS.alignment = NSNaturalTextAlignment ;   }
                else {
                    luaL_error(L, [[NSString stringWithFormat:@"invalid alignment: %@", theString] UTF8String]) ;
                    return nil ;
                }
            }
            lua_pop(L, 1);
            if (lua_getfield(L, -1, "lineBreak") == LUA_TSTRING) {  // for backwards compatibility with hs.drawing.setTextStyle
                NSString *theString = [NSString stringWithUTF8String:luaL_checkstring(L, -1)];
                if ([theString isEqualToString:@"wordWrap"])       { thePS.lineBreakMode = NSLineBreakByWordWrapping ;     } else
                if ([theString isEqualToString:@"charWrap"])       { thePS.lineBreakMode = NSLineBreakByCharWrapping ;     } else
                if ([theString isEqualToString:@"clip"])           { thePS.lineBreakMode = NSLineBreakByClipping ;         } else
                if ([theString isEqualToString:@"truncateHead"])   { thePS.lineBreakMode = NSLineBreakByTruncatingHead ;   } else
                if ([theString isEqualToString:@"truncateTail"])   { thePS.lineBreakMode = NSLineBreakByTruncatingTail ;   } else
                if ([theString isEqualToString:@"truncateMiddle"]) { thePS.lineBreakMode = NSLineBreakByTruncatingMiddle ; }
                else {
                    luaL_error(L, [[NSString stringWithFormat:@"invalid lineBreakMode: %@", theString] UTF8String]) ;
                    return nil ;
                }
            }
            lua_pop(L, 1);
            if (lua_getfield(L, -1, "baseWritingDirection") == LUA_TSTRING) {
                NSString *theString = [NSString stringWithUTF8String:luaL_checkstring(L, -1)];
                if ([theString isEqualToString:@"natural"])     { thePS.baseWritingDirection = NSWritingDirectionNatural ;     } else
                if ([theString isEqualToString:@"leftToRight"]) { thePS.baseWritingDirection = NSWritingDirectionLeftToRight ; } else
                if ([theString isEqualToString:@"rightToLeft"]) { thePS.baseWritingDirection = NSWritingDirectionRightToLeft ; }
                else {
                    luaL_error(L, [[NSString stringWithFormat:@"invalid baseWritingDirection: %@", theString] UTF8String]) ;
                    return nil ;
                }
            }
            lua_pop(L, 1);
            if (lua_getfield(L, -1, "defaultTabInterval") == LUA_TNUMBER) {
                lua_Number theNumber = lua_tonumber(L, -1) ;
                if (theNumber >= 0.0) {
                    thePS.defaultTabInterval = theNumber ;
                } else {
                    luaL_error(L, "defaultTabInterval must be non-negative") ;
                    return nil ;
                }
            }
            lua_pop(L, 1);
            if (lua_getfield(L, -1, "firstLineHeadIndent") == LUA_TNUMBER) {
                lua_Number theNumber = lua_tonumber(L, -1) ;
                if (theNumber >= 0.0) {
                    thePS.firstLineHeadIndent = theNumber ;
                } else {
                    luaL_error(L, "firstLineHeadIndent must be non-negative") ;
                    return nil ;
                }
            }
            lua_pop(L, 1);

            if (lua_getfield(L, -1, "headIndent") == LUA_TNUMBER) {
                lua_Number theNumber = lua_tonumber(L, -1) ;
                if (theNumber >= 0.0) {
                    thePS.headIndent = theNumber ;
                } else {
                    luaL_error(L, "headIndent must be non-negative") ;
                    return nil ;
                }
            }
            lua_pop(L, 1);
            if (lua_getfield(L, -1, "tailIndent") == LUA_TNUMBER) {
                thePS.tailIndent = lua_tonumber(L, -1) ;
            }
            lua_pop(L, 1);
            if (lua_getfield(L, -1, "maximumLineHeight") == LUA_TNUMBER) {
                lua_Number theNumber = lua_tonumber(L, -1) ;
                if (theNumber >= 0.0) {
                    thePS.maximumLineHeight = theNumber ;
                } else {
                    luaL_error(L, "maximumLineHeight must be non-negative") ;
                    return nil ;
                }
            }
            lua_pop(L, 1);
            if (lua_getfield(L, -1, "minimumLineHeight") == LUA_TNUMBER) {
                lua_Number theNumber = lua_tonumber(L, -1) ;
                if (theNumber >= 0.0) {
                    thePS.minimumLineHeight = theNumber ;
                } else {
                    luaL_error(L, "minimumLineHeight must be non-negative") ;
                    return nil ;
                }
            }
            lua_pop(L, 1);
            if (lua_getfield(L, -1, "lineSpacing") == LUA_TNUMBER) {
                lua_Number theNumber = lua_tonumber(L, -1) ;
                if (theNumber >= 0.0) {
                    thePS.lineSpacing = theNumber ;
                } else {
                    luaL_error(L, "lineSpacing must be non-negative") ;
                    return nil ;
                }
            }
            lua_pop(L, 1);
            if (lua_getfield(L, -1, "paragraphSpacing") == LUA_TNUMBER) {
                lua_Number theNumber = lua_tonumber(L, -1) ;
                if (theNumber >= 0.0) {
                    thePS.paragraphSpacing = theNumber ;
                } else {
                    luaL_error(L, "paragraphSpacing must be non-negative") ;
                    return nil ;
                }
            }
            lua_pop(L, 1);
            if (lua_getfield(L, -1, "paragraphSpacingBefore") == LUA_TNUMBER) {
                lua_Number theNumber = lua_tonumber(L, -1) ;
                if (theNumber >= 0.0) {
                    thePS.paragraphSpacingBefore = theNumber ;
                } else {
                    luaL_error(L, "paragraphSpacingBefore must be non-negative") ;
                    return nil ;
                }
            }
            lua_pop(L, 1);
            if (lua_getfield(L, -1, "lineHeightMultiple") == LUA_TNUMBER) {
                lua_Number theNumber = lua_tonumber(L, -1) ;
                if (theNumber >= 0.0) {
                    thePS.lineHeightMultiple = theNumber ;
                } else {
                    luaL_error(L, "lineHeightMultiple must be non-negative") ;
                    return nil ;
                }
            }
            lua_pop(L, 1);
            if (lua_getfield(L, -1, "hyphenationFactor") == LUA_TNUMBER) {
                lua_Number theNumber = lua_tonumber(L, -1) ;
                if (theNumber >= 0.0 && theNumber <= 1.0) {
                    thePS.hyphenationFactor = (float) theNumber ;
                } else {
                    luaL_error(L, "hyphenationFactor must be between 0.0 and 1.0 inclusive") ;
                    return nil ;
                }
            }
            lua_pop(L, 1);
            if (lua_getfield(L, -1, "tighteningFactorForTruncation") == LUA_TNUMBER) {
                thePS.tighteningFactorForTruncation = (float) lua_tonumber(L, -1) ;
            }
            lua_pop(L, 1);
            break;

        default:
            luaL_error(L, [[NSString stringWithFormat:@"Unexpected type passed as a NSParagraphStyle: %s", lua_typename(L, lua_type(L, idx))] UTF8String]) ;
            return nil ;
            break;
    }

    lua_pop(L, 1);
    return thePS ;
}

static int setTextWithStyle(lua_State *L) {
    drawing_t         *drawingObject = ((drawing_t *)luaL_checkudata(L, 1, "hs.drawing")) ;
    HSDrawingWindow   *drawingWindow = (__bridge HSDrawingWindow *)drawingObject->window;
    HSDrawingViewText *drawingView = (HSDrawingViewText *)drawingWindow.contentView;
    NSTextField       *theTextField = drawingView.textField ;

    if (theTextField) {
        luaL_checktype(L, 2, LUA_TTABLE) ;
        theTextField.attributedStringValue = [[LuaSkin shared] tableAtIndex:2 toClass:"NSAttributedString"] ;
    } else {
        return luaL_error(L, ":setTextWithStyle() called on an hs.drawing object that isn't a text object") ;
    }

    lua_pushvalue(L, 1);
    return 1;
}

static int getTextWithStyle(lua_State *L) {
    drawing_t         *drawingObject = ((drawing_t *)luaL_checkudata(L, 1, "hs.drawing")) ;
    HSDrawingWindow   *drawingWindow = (__bridge HSDrawingWindow *)drawingObject->window;
    HSDrawingViewText *drawingView = (HSDrawingViewText *)drawingWindow.contentView;
    NSTextField       *theTextField = drawingView.textField ;

    if (theTextField) {
        [[LuaSkin shared] pushNSObject:theTextField.attributedStringValue] ;

        // The following is to maintain compatibility with hs.drawing without requiring a re-write of all of the
        // text related methods to our implementation of the "NSAttributedString" type.  If hs.drawing is changed
        // then the following won't be necessary.

        lua_geti(L, -1, 2) ;
          int tableIndex = lua_absindex(L, -1) ;
          if (lua_getfield(L, -1, "font") == LUA_TNIL) {
              NSFont *theFont = theTextField.font ;
              lua_pushstring(L, [[theFont fontName] UTF8String]) ; lua_setfield(L, tableIndex, "font") ;
              lua_pushnumber(L, [theFont pointSize]) ;             lua_setfield(L, tableIndex, "size") ;
          }
          lua_pop(L, 1) ;

          if (lua_getfield(L, -1, "color") == LUA_TNIL) {
              [[LuaSkin shared] pushNSObject:theTextField.textColor] ;
              lua_setfield(L, tableIndex, "color") ;
          }
          lua_pop(L, 1) ;
        lua_pop(L, 1) ;
    } else {
        return luaL_error(L, ":getTextWithStyle() called on an hs.drawing object that isn't a text object") ;
    }

    return 1;
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
    {"setTextWithStyle", setTextWithStyle},
    {"getTextWithStyle", getTextWithStyle},
    {NULL,               NULL}
};

// // Metatable for module, if needed
// static const luaL_Reg module_metaLib[] = {
//     {"__gc", meta_gc},
//     {NULL,   NULL}
// };

// NOTE: ** Make sure to change luaopen_..._internal **
int luaopen_hs__asm_text_internal(lua_State* __unused L) {
    LuaSkin *skin = [LuaSkin shared];

    refTable = [skin registerLibrary:moduleLib metaFunctions:nil] ; // or module_metaLib

    [skin registerPushNSHelper:NSShadow_tolua forClass:"NSShadow"] ;
    [skin registerTableHelper:table_toNSShadow forClass:"NSShadow"] ;

    [skin registerPushNSHelper:NSColor_tolua forClass:"NSColor"] ;
    [skin registerTableHelper:table_toNSColor forClass:"NSColor"] ;

    [skin registerPushNSHelper:NSParagraphStyle_tolua forClass:"NSParagraphStyle"] ;
    [skin registerTableHelper:table_toNSParagraphStyle forClass:"NSParagraphStyle"] ;

    return 1;
}
