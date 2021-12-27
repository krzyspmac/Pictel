//
//  path_finder_line_graph_node.cpp
//  Engine
//
//  Created by krzysp on 27/12/2021.
//

#include "path_finder_line_graph_node.hpp"

using namespace engine;

PathFinderLineGraphNode::PathFinderLineGraphNode(Vector2 *point)
: PathFinderLineGraphNodeI(point)
{

}

void PathFinderLineGraphNode::AddConnection(PathFinderLineGraphNodeI *node)
{
    m_connectingNodes.emplace_back(node);
}

std::vector<PathFinderLineGraphNodeI*>& PathFinderLineGraphNode::GetConnections()
{
    return m_connectingNodes;
}

bool PathFinderLineGraphNode::HasConnectionWithPoint(Vector2 *point)
{
    Vector2 &targetPoint = *point;

    for (auto it = std::begin(m_connectingNodes); it != std::end(m_connectingNodes); ++it)
    {
        PathFinderLineGraphNodeI *stored = *it;
        Vector2 *storedPointEx = stored->GetPoint();
        Vector2 &storedPoint = *(storedPointEx);

        if (Vector2Equals(targetPoint, storedPoint))
        {
            return true;
        }
    }
    return false;
}

void PathFinderLineGraphNode::RPathClearUpTo(std::vector<PathFinderLineGraphNodeI*> *pathStack, PathFinderLineGraphNodeI *upToHere)
{
    int foundIndex = -1;

    for (int i = 0; i < pathStack->size(); i++)
    {
        PathFinderLineGraphNodeI *node = pathStack->at(i);
        if (node == upToHere)
        {
            foundIndex = i;
        }
    }

    for (int i = pathStack->size()-1; i > foundIndex; i--)
    {
        pathStack->pop_back();
    }
}

bool PathFinderLineGraphNode::RPathContains(std::vector<PathFinderLineGraphNodeI*> *pathStack, PathFinderLineGraphNodeI *targetNode)
{
    for (int i = 0; i < pathStack->size(); i++)
    {
        PathFinderLineGraphNodeI *node = pathStack->at(i);
        if (node == targetNode)
        {
            return true;;
        }
    }

    return false;;
}

float PathFinderLineGraphNode::RPathDistance(std::vector<PathFinderLineGraphNodeI*> *pathStack)
{
    float distance = 0;
    size_t count = pathStack->size();

    for (int i = 0; i < count; i++)
    {
        if (i+1 >= count)
        {
            break;;
        }

        PathFinderLineGraphNodeI *node = pathStack->at(i);
        PathFinderLineGraphNodeI *nextNode = pathStack->at(i+1);

        Vector2 nodePoint = *node->GetPoint();
        Vector2 nextNodePoint = *nextNode->GetPoint();

        Line line(nodePoint, nextNodePoint);
        distance += line.GetLength();
    }

    return distance;
}

void PathFinderLineGraphNode::DistanceToPoint(PathFinderBaseI *sender, Vector2 &targetPoint, std::vector<PathFinderLineGraphNodeI*> *pathStack)
{
    pathStack->emplace_back(this); // put back to the stack; we don't want to traverse the same point again

    Line targetLine(*m_point, targetPoint);
    if (!PathFinderUtils::IntersectsAnyline(targetLine, sender->GetAllPoint(), sender->GetAllLines()))
    {
            // If there's a connection and we're not crossing any other lines it's a hit!
        sender->DidFind();
        return;
    }

    if (m_connectingNodes.size() < 1)
    {
            // Can't go anywhere further.
        return;
    }

    for (auto it = std::begin(m_connectingNodes); it != std::end(m_connectingNodes); ++it)
    {
            // clear all traversed point up to certain point; should be somewhere at the end
        PathFinderLineGraphNode::RPathClearUpTo(pathStack, this);

        PathFinderLineGraphNodeI *node = *it;

        if (RPathContains(pathStack, node))
        {
            continue;
        }

        Vector2 *point = node->GetPoint();
        if (!PathFinderUtils::IsPointWithingViewport(*point))
        {
            continue;
        }

        node->DistanceToPoint(sender, targetPoint, pathStack);
    }
}