//
//  size.hpp
//  Engine
//
//  Created by krzysp on 25/09/2022.
//

#ifndef size_h
#define size_h

namespace engine
{

    typedef struct Size
    {
        int width;
        int height;
    } Size;

    typedef struct
    {
        float r;
        float g;
        float b;
    } Color3;

    typedef struct
    {
        float r;
        float g;
        float b;
        float a;
    } Color4;

    typedef struct
    {
        int x;
        int y;
    } Origin;

    typedef struct
    {
        Origin origin;
        Size size;
    } Rect;

    typedef struct
    {
        float x;
        float y;
    } OriginF;

    typedef struct
    {
        float width;
        float height;
    } SizeF;

    typedef struct
    {
        OriginF origin;
        SizeF size;
    } RectF;

    inline Origin OriginMake(int x, int y)
    {
        Origin result;
        result.x = x;
        result.y = y;
        return result;
    };

    inline Origin OriginGetDiff(Origin &first, Origin &second)
    {
        Origin result;
        result.x = first.x - second.x;
        result.y = first.y - second.y;
        return result;
    }

    inline bool OriginEquals(Origin &first, Origin &second)
    {
        return first.x == second.x && first.y == second.y;
    }
}

#endif /* size_h */