import std.stdio, std.string, std.array, std.datetime;
import position;
import move;
import squares;
import square;
import rays;


class Tree {
    Position pos;
    ulong leaves_searched;
    ulong nodes_searched;
    int   alpha;
    int   beta;
    int   best_score;
    int   ctm;
    Move  best_move;
    StopWatch timer;
    double runtime;
    enum neginf = -128;
    enum posinf = 128;
    
    this(Position search_position) {
        pos = new Position;
        for (int i=0; i<64; i++) {
            pos.num_moves[i] = search_position.num_moves[i];
            for (int j=0; j<128; j++)
                pos.move_list[j][i] = search_position.move_list[j][i];
        }
        pos.position_index = search_position.position_index;
        pos.passed = search_position.passed;
        pos.black_stones = search_position.black_stones;
        pos.white_stones = search_position.white_stones;
        pos.side_to_move = search_position.side_to_move;
        ctm = search_position.side_to_move;
        pos.sqs = new Squares();
        pos.s_test = new Square();
        pos.ray_list = new Rays();
        pos.hashkey = search_position.hashkey;
        leaves_searched = 0;
        nodes_searched = 0;
        alpha = neginf;
        beta = posinf;
        best_score = 0;
        best_move = new Move;
        runtime = 0.0;
    }
}


int pvsSearch (ref Tree tree, int alpha, int beta, int depth, int ctm, bool passed) {
    int score;


    tree.nodes_searched++;
    if (depth == 0) {
        tree.leaves_searched++;
        return (tree.pos.evaluate(ctm));
    }
    tree.pos.generateRayMoves();
    if (tree.pos.num_moves[tree.pos.position_index] == 0) {
        if (passed) {
            tree.leaves_searched++;
            return tree.pos.eog_evaluate(ctm);
        }
        tree.pos.makePass();
        score = -pvsSearch(tree, -beta, -alpha, depth, (ctm^1), true);
        tree.pos.unmakePass();
        tree.pos.move_list[tree.pos.position_index][0].sq_num = 99;
        tree.pos.move_list[tree.pos.position_index][0].score = score;
    }  
    else {
        for (int m=0; m<tree.pos.num_moves[tree.pos.position_index]; m++) {
            if (m != 0) {
                tree.pos.makeMove(tree.pos.move_list[tree.pos.position_index][m]);
                score = -pvsSearch(tree, (-alpha - 1), -alpha, (depth-1), (ctm^1), false);
                if ((alpha < score) && (score < beta))  
                    score = -pvsSearch(tree, -beta, -alpha, (depth-1), (ctm^1), false);
                tree.pos.unmakeMove(tree.pos.move_list[tree.pos.position_index-1][m]);
                tree.pos.move_list[tree.pos.position_index][m].score = score;
            }        
            else {
                tree.pos.makeMove(tree.pos.move_list[tree.pos.position_index][m]);
                score = -pvsSearch(tree, -beta, -alpha, (depth-1), (ctm^1), false);
                tree.pos.unmakeMove(tree.pos.move_list[tree.pos.position_index-1][m]);
                tree.pos.move_list[tree.pos.position_index][m].score = score;
            }
            if (score > alpha)
                alpha = score;
            if (alpha >= beta)
                break; // add killer move
        }
    }
//    tree.pos.printMoveList();
    return alpha;
}
/*
function pvs(node, depth, α, β, color)
    if node is a terminal node or depth = 0
        return color × the heuristic value of node
    for each child of node
        if child is not first child
            score := -pvs(child, depth-1, -α-1, -α, -color)       (* search with a null window *)
            if α < score < β                                      (* if it failed high,
                score := -pvs(child, depth-1, -β, -α, -color)        do a full re-search *)
        else
            score := -pvs(child, depth-1, -β, -α, -color)
        α := max(α, score)
        if α ≥ β
            break                                            (* beta cut-off *)
    return α

*/