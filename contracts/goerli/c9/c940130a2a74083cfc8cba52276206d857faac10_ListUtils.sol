pragma solidity ^0.8.13;

library ListUtils {

     function prune(string[] memory list, uint256[] memory prunes) public pure returns (string [] memory) {
        string [] memory pruned = new string[](list.length - prunes.length);
        uint c = 0;
        for (uint i=0; i < list.length && c < pruned.length; i++) {
            bool found = false;
            for (uint j=0; j < prunes.length; j++) {
                if (i == prunes[j]) {
                    found = true;
                    break;
                }
            }
            // if its in the list we need to not allow it
            if (!found) {
                pruned[c++] = list[i];
            }
        }
        return pruned;
    }

    function byIndices(
        string[] memory list, 
        uint[] memory indices) 
    public pure returns (string [] memory) {
        string [] memory filtered = new string[](indices.length);
        for (uint i=0; i < indices.length; i++) {
            filtered[i] = list[indices[i] % list.length];
        }
        return filtered;
    }

    function count(
        int8[] memory list,
        int s) public pure returns (uint) {
        
        uint c = 0;
        for (uint i=0; i < list.length; i++) {
            if (list[i] == s) {
                c++;
            }
        }
        return c;
    }
    
}