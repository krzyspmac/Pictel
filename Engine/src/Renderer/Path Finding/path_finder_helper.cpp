// Copyright (c) 2022 Krzysztof Pawłowski
//
// Permission is hereby granted, free of charge, to any person obtaining a copy of
// this software and associated documentation files (the "Software"), to deal in the
// Software without restriction, including without limitation the rights to use, copy,
// modify, merge, publish, distribute, sublicense, and/or sell copies of the Software,
// and to permit persons to whom the Software is furnished to do so, subject to the
// following conditions:
//
// The above copyright notice and this permission notice shall be included in all copies
// or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
// INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
// PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
// LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
// TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE
// OR OTHER DEALINGS IN THE SOFTWARE.

#include "path_finder_helper.hpp"
#include "engine.hpp"
#include "path.hpp"

using namespace engine;

bool PathFinderUtils::PointListIncludesPoint(Vector2 &point, std::vector<Vector2> &points)
{
    for (auto it = std::begin(points); it != std::end(points); ++it)
    {
        Vector2 &vp = *it;
        if (vp.x == point.x && vp.y == point.y)
        {
            return true;
        }
    }
    return false;
}

bool PathFinderUtils::IntersectsAnyline(Line &myLine, std::vector<Vector2> &m_allPoint, std::vector<Line> &m_allLines)
{
    Vector2 &p0 = myLine.GetP1();
    Vector2 &p1 = myLine.GetP2();

    bool intersects = false;

    for (auto lit = std::begin(m_allLines); lit != std::end(m_allLines); ++lit)
    {
        Line &line = *lit;
        Vector2 &p2 = line.GetP1();
        Vector2 &p3 = line.GetP2();

        float i_x;
        float i_y;

        if (GetLineIntersection(p0.x, p0.y, p1.x, p1.y, p2.x, p2.y, p3.x, p3.y, &i_x, &i_y))
        {
            Vector2 intersectionPoint;
            intersectionPoint.x = i_x;
            intersectionPoint.y = i_y;

            if (!PointListIncludesPoint(intersectionPoint, m_allPoint))
            {
                intersects = true;
                break;
            }
        }
    }

    return intersects;
}

std::vector<Line*> PathFinderUtils::IntersectsLines(Line &myLine, std::vector<Line> &m_allLines)
{
    std::vector<Line*> result;

    Vector2 &p0 = myLine.GetP1();
    Vector2 &p1 = myLine.GetP2();

    for (auto lit = std::begin(m_allLines); lit != std::end(m_allLines); ++lit)
    {
        Line &line = *lit;
        Vector2 &p2 = line.GetP1();
        Vector2 &p3 = line.GetP2();

        float i_x;
        float i_y;

        if (GetLineIntersection(p0.x, p0.y, p1.x, p1.y, p2.x, p2.y, p3.x, p3.y, &i_x, &i_y))
        {
            Vector2 intersectionPoint;
            intersectionPoint.x = i_x;
            intersectionPoint.y = i_y;

            Line *line = &(*lit);
            result.emplace_back(line);
        }
    }

    return result;
}

bool PathFinderUtils::IsPointWithingViewport(Vector2 &point)
{
    Size &viewportSize = ENGINE().GetViewport();
    if (point.x > 0 && point.x < viewportSize.width && point.y > 0 && point.y < viewportSize.height)
    {
        return true;
    }
    else
    {
        return false;
    }
};

// Andre LeMothe's "Tricks of the Windows Game Programming Gurus".
// Returns 1 if the lines intersect, otherwise 0. In addition, if the lines
// intersect the intersection point may be stored in the floats i_x and i_y.
char PathFinderUtils::GetLineIntersection(float p0_x, float p0_y, float p1_x, float p1_y,
    float p2_x, float p2_y, float p3_x, float p3_y, float *i_x, float *i_y)
{
    float s1_x, s1_y, s2_x, s2_y;
    s1_x = p1_x - p0_x;     s1_y = p1_y - p0_y;
    s2_x = p3_x - p2_x;     s2_y = p3_y - p2_y;

    float s, t;
    s = (-s1_y * (p0_x - p2_x) + s1_x * (p0_y - p2_y)) / (-s2_x * s1_y + s1_x * s2_y);
    t = ( s2_x * (p0_y - p2_y) - s2_y * (p0_x - p2_x)) / (-s2_x * s1_y + s1_x * s2_y);

    if (s >= 0 && s <= 1 && t >= 0 && t <= 1)
    {
        // Collision detected
        if (i_x != NULL)
            *i_x = p0_x + (t * s1_x);
        if (i_y != NULL)
            *i_y = p0_y + (t * s1_y);
        return 1;
    }

    return 0; // No collision
}

std::vector<Vector2> PathFinderUtils::ListOfNodesToVectors(std::vector<PathFinderLineGraphNodeI*> *list, float nudgeFactor)
{
    std::vector<Vector2> result;

    for (auto lit = std::begin(*list); lit != std::end(*list); ++lit)
    {
        PathFinderLineGraphNodeI *node = *lit;
        Vector2 normal = Vector2Scaled(node->GetNormal(), nudgeFactor);
        Vector2 nudgedPoint = Vector2Add(*node->GetPoint(), normal);
        result.push_back(nudgedPoint);
    }

    return result;
}

std::unique_ptr<PathI> PathFinderUtils::NodesToPath(std::vector<PathFinderLineGraphNodeI*> *nodes, Vector2 startingPostion, Vector2 endingPosition, float nudgeFactor)
{
    std::vector<Vector2> points;
    points.push_back(startingPostion);

    if (nodes != nullptr)
    {
        for (auto lit = std::begin(*nodes); lit != std::end(*nodes); ++lit)
        {
            PathFinderLineGraphNodeI *node = *lit;
            Vector2 normal = Vector2Scaled(node->GetNormal(), nudgeFactor);
            Vector2 nudgedPoint = Vector2Add(*node->GetPoint(), normal);
            points.push_back(nudgedPoint);
        }
    }
    
    points.push_back(endingPosition);

    return std::unique_ptr<PathI>(std::move(new Path(points)));
}
