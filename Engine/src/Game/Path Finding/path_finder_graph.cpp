//
//  path_finder_graph.cpp
//  Engine
//
//  Created by krzysp on 27/12/2021.
//

#include "path_finder_graph.hpp"
#include "path_finder_line_graph_node.hpp"

using namespace engine;

static int max_iteration = 1024;
static int cur_iteration = 0;

PathFinderGraph::PathFinderGraph(std::vector<Line> lines)
: PathFinderGraphI(lines)
{
    Prepare();
}

PathFinderLineGraphNodeI *PathFinderGraph::GetNodeForPoint(Vector2 &point)
{
    for (auto it = std::begin(m_nodes); it != std::end(m_nodes); ++it)
    {
        PathFinderLineGraphNodeI *node = it->get();
        Vector2 *nodePoint = node->GetPoint();
        if (Vector2Equals(point, *nodePoint))
        {
            return node;
        }

    }
    return NULL;
}

void PathFinderGraph::Prepare()
{
    // Store a list of graph nodes. The number of nodes is equal to the number of lines.
    for (auto it = std::begin(m_connectingLines); it != std::end(m_connectingLines); ++it)
    {
        Line *line = &(*it);
        Vector2 &p1 = line->GetP1();
        Vector2 &p2 = line->GetP2();

        PathFinderLineGraphNodeI *nodeP1 = GetNodeForPoint(p1);
        if (!nodeP1)
        {
            nodeP1 = new PathFinderLineGraphNode(&(p1));
            m_nodes.emplace_back(std::move(nodeP1));
        }

        PathFinderLineGraphNodeI *nodeP2 = GetNodeForPoint(p2);
        if (!nodeP2)
        {
            nodeP2 = new PathFinderLineGraphNode(&(p2));
            m_nodes.emplace_back(std::move(nodeP2));
        }
    }

    // Go through each point node and check if it connects, via line,
    // to any other node.
    for (auto it = std::begin(m_nodes); it != std::end(m_nodes); ++it)
    {
        PathFinderLineGraphNodeI *node = it->get();
        Vector2 *nodePoint = node->GetPoint();

        for (auto pit = std::begin(m_nodes); pit != std::end(m_nodes); ++pit)
        {
            PathFinderLineGraphNodeI *otherNode = pit->get();
            Vector2 *otherNodePoint = otherNode->GetPoint();

            if (node == otherNode)
            {
                // skip the same items
                continue;
            }

            for (auto lit = std::begin(m_connectingLines); lit != std::end(m_connectingLines); ++lit)
            {
                Line &line = *lit;
                if (line.HasVertex(*nodePoint) && line.HasVertex(*otherNodePoint))
                {
                    if (!node->HasConnectionWithPoint(otherNodePoint))
                    {
                        node->AddConnection(otherNode);
                    }
                }
            }
        }
    }
};

void PathFinderGraph::DistanceToPoint(PathFinderBaseI *sender, Vector2 &startingPoint, Vector2 &targetPoint, std::vector<PathFinderLineGraphNodeI*> *pathStack)
{
    pathStack->clear();
    cur_iteration = 0;

    for (auto it = std::begin(m_nodes); it != std::end(m_nodes); ++it)
    {
        if (++cur_iteration >= max_iteration) {
            return;
        }

        PathFinderLineGraphNodeI *node = it->get();
        Vector2 &point = *node->GetPoint();

        if (!PathFinderUtils::IsPointWithingViewport(point))
        {
            continue;
        }

        // Check if we can see the first node
        Line lineToFirstNode(startingPoint, point);

        if (PathFinderUtils::IntersectsAnyline(lineToFirstNode, sender->GetAllPoint(), sender->GetAllLines()))
        {
            continue;
        }

        sender->DidStart(lineToFirstNode.GetLength());

        node->DistanceToPoint(sender, targetPoint, pathStack);
    }
}