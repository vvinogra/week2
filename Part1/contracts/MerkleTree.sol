//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import { PoseidonT3 } from "./Poseidon.sol"; //an existing library to perform Poseidon hash on solidity
import "./verifier.sol"; //inherits with the MerkleTreeInclusionProof verifier contract

contract MerkleTree is Verifier {
    uint256[] public hashes; // the Merkle tree in flattened array form
    uint256 public index = 0; // the current index of the first unfilled leaf
    uint256 public root; // the current Merkle root

    uint constant DEFAULT_LEVEL = 3;

    constructor() {
        // [assignment] initialize a Merkle tree of 8 with blank leaves
        uint totalOffset = 0;
        uint prevOffset = 0;

        // First level
        for (uint j = 0; j < 2 ** DEFAULT_LEVEL; j++) {
            hashes.push(0);
        }
        prevOffset = 2 ** DEFAULT_LEVEL;
        totalOffset += prevOffset;

        // Other levels
        uint256[2] memory valuesForHashing;

        for (uint i = 1; i <= DEFAULT_LEVEL; i++) {
            for (uint j = 0; j < 2 ** (DEFAULT_LEVEL - i); j++) {
                uint offsetWithoutPreviousOffset = totalOffset - prevOffset;

                uint jDoubledWithOffset = j * 2 + offsetWithoutPreviousOffset;

                valuesForHashing[0] = hashes[jDoubledWithOffset];
                valuesForHashing[1] = hashes[jDoubledWithOffset + 1];

                uint256 hashResult = PoseidonT3.poseidon(valuesForHashing);

                hashes.push(hashResult);
            }

            prevOffset = 2 ** (DEFAULT_LEVEL - i);
            totalOffset += prevOffset;
        }
    }

    function insertLeaf(uint256 hashedLeaf) public returns (uint256) {
        // [assignment] insert a hashed leaf into the Merkle tree
        uint256[2] memory valuesForHashing;
        uint totalOffset = 0;

        uint currentHash = hashedLeaf;
        uint currentIndex = index;

        // Updating current index value
        hashes[index] = hashedLeaf;

        for (uint i = 0; i < DEFAULT_LEVEL; i++) {
            uint levelOffset = 2 ** (DEFAULT_LEVEL - i);
            uint nextLevelNodeNumber;

            uint currentRelativeToLevelIndex = currentIndex - totalOffset;

            if (currentIndex % 2 == 0) {
                valuesForHashing[0] = currentHash;
                valuesForHashing[1] = hashes[currentIndex + 1];

                nextLevelNodeNumber = currentRelativeToLevelIndex / 2;
            } else {
                valuesForHashing[0] = hashes[currentIndex - 1];
                valuesForHashing[1] = currentHash;

                nextLevelNodeNumber = (currentRelativeToLevelIndex - 1) / 2;
            }

            currentHash = PoseidonT3.poseidon(valuesForHashing);

            totalOffset += levelOffset;

            currentIndex = totalOffset + nextLevelNodeNumber;
            hashes[currentIndex] = currentHash;
        }

        // Incrementing leaf index. In case of overflow, reset to the beginning
        index++;

        if (index >= 8) {
            index = 0;
        }

        return index;
    }

    function verify(
            uint[2] memory a,
            uint[2][2] memory b,
            uint[2] memory c,
            uint[1] memory input
        ) public view returns (bool) {

        // [assignment] verify an inclusion proof and check that the proof root matches current root
        return verifyProof(a, b, c, input) && input[0] == getMerkleTreeRoot();
    }

    function getMerkleTreeRoot() private view returns (uint256) {
        return hashes[hashes.length - 1];
    }
}
