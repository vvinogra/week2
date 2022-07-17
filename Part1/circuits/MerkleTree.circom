pragma circom 2.0.0;

include "../node_modules/circomlib/circuits/poseidon.circom";
include "../node_modules/circomlib/circuits/mux1.circom";

template CheckRoot(n) { // compute the root of a MerkleTree of n Levels 
    signal input leaves[2**n];
    signal output root;

    //[assignment] insert your code here to calculate the Merkle root from 2^n leaves
    component treeNodes[2**n - 1];

    // Calculating tree nodes from initial hashes
    var totalOffset = 0;
    var previousOffset = 0;

    if (2**n == 1) {
        // Case where n == 0
        root <== leaves[0];
    } else {
        for (var i = 1; i <= n; i++) {
            if (i == 1) {
                for (var j = 0; j < 2 ** (n - i); j++) {
                    treeNodes[j] = Poseidon(2);

                    treeNodes[j].inputs[0] <== leaves[j * 2];
                    treeNodes[j].inputs[1] <== leaves[(j * 2) + 1];
                }
            } else {
                for (var j = 0; j < 2 ** (n - i); j++) {
                    var jTimesTwoWithoutPreviousOffset = (j * 2) + (totalOffset - previousOffset);

                    var jWithOffset = j + totalOffset;

                    treeNodes[jWithOffset] = Poseidon(2);

                    treeNodes[jWithOffset].inputs[0] <== treeNodes[jTimesTwoWithoutPreviousOffset].out;
                    treeNodes[jWithOffset].inputs[1] <== treeNodes[jTimesTwoWithoutPreviousOffset + 1].out;
                }
            }

            previousOffset = 2 ** (n - i);
            totalOffset += previousOffset;
        }

        root <== treeNodes[totalOffset - 1].out;
    }
}

template MerkleTreeInclusionProof(n) {
    signal input leaf;
    signal input path_elements[n];
    signal input path_index[n]; // path index are 0's and 1's indicating whether the current element is on the left or right
    signal output root; // note that this is an OUTPUT signal

    //[assignment] insert your code here to compute the root from a leaf and elements along the path
    component treeNodes[n];
    component muxComponents[n];
    var hash = leaf;

    for (var i = 0; i < n; i++) {
        treeNodes[i] = Poseidon(2);
        muxComponents[i] = MultiMux1(2);

        // Choosing left element
        muxComponents[i].c[0][0] <== hash;
        muxComponents[i].c[0][1] <== path_elements[i];

        // Choosing right element
        muxComponents[i].c[1][0] <== path_elements[i];
        muxComponents[i].c[1][1] <== hash;

        muxComponents[i].s <== path_index[i];

        treeNodes[i].inputs[0] <== muxComponents[i].out[0];
        treeNodes[i].inputs[1] <== muxComponents[i].out[1];

        hash = treeNodes[i].out;
    }

    root <== hash;
}