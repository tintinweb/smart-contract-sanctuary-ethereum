// SPDX-License-Identifier: MIT
/*****************************************************************************************************************************************************
 @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@  [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@        (@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 @@@@@@@@@@@@@@@@@@@@@          @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@         @@@@@@@@@@          @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 @@@@@@@@@@@@@@@@@@@@            @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@         @@@@@@@@@@@        @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 @@@@@@@@@@@@@@@@@@@              @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@         @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 @@@@@@@@@@@@@@@@@@                &@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@         @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@        @@@@@@@@@@@@@@@@@@@@
 @@@@@@@@@@@@@@@@@        @@        [email protected]@@@@@@@@@@@@@@         @         @@                       @@,        @@@@@@@@@,                  @@@@@@@@@@@@@@@
 @@@@@@@@@@@@@@@@        @@@@         @@@@@@@@@@@@@@                   @@                       @@,        @@@@@@@                        @@@@@@@@@@@@
 @@@@@@@@@@@@@@@        @@@@@@         @@@@@@@@@@@@@                   @@                       @@,        @@@@@          (@@@@@@          @@@@@@@@@@@
 @@@@@@@@@@@@@(        @@@@@@@@         @@@@@@@@@@@@          @@@@@@@@@@@@@@@@@         @@@@@@@@@@,        @@@@         @@@@@@@@@@@         @@@@@@@@@@
 @@@@@@@@@@@@         @@@@@@@@@@         @@@@@@@@@@@         @@@@@@@@@@@@@@@@@@         @@@@@@@@@@,        @@@         @@@@@@@@@@@&%         @@@@@@@@@
 @@@@@@@@@@@                              @@@@@@@@@@         @@@@@@@@@@@@@@@@@@         @@@@@@@@@@,        @@@                               @@@@@@@@@
 @@@@@@@@@@                                @@@@@@@@@         @@@@@@@@@@@@@@@@@@         @@@@@@@@@@,        @@@                               @@@@@@@@@
 @@@@@@@@@                                  @@@@@@@@         @@@@@@@@@@@@@@@@@@         @@@@@@@@@@,        @@@         @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 @@@@@@@@                                    @@@@@@@         @@@@@@@@@@@@@@@@@@          @@@@@@@@@.        @@@@         @@@@@@@@@@@@@@ @@@@@@@@@@@@@@@
 @@@@@@@         @@@@@@@@@@@@@@@@@@@@         @@@@@@         @@@@@@@@@@@@@@@@@@                 @@,        @@@@@            @@@@@         @@@@@@@@@@@@
 @@@@@@         @@@@@@@@@@@@@@@@@@@@@@         @@@@@         @@@@@@@@@@@@@@@@@@@                @@,        @@@@@@@                         @@@@@@@@@@@
 @@@@@         @@@@@@@@@@@@@@@@@@@@@@@@         @@@@         @@@@@@@@@@@@@@@@@@@@               @@,        @@@@@@@@@@                   @@@@@@@@@@@@@@
 @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@     (@@@@@@@@@@@@@@@@@@@@
 @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
*****************************************************************************************************************************************************/
pragma solidity ^0.8.0;

interface IDispensary {
    function safeMint(address to, uint256 id, uint256 amount, bytes calldata data) external;
    function safeBurn(address to, uint256 tokenID, uint256 amount) external;
}

interface IHashGenerator {
    function generateHash(uint256 i) external view returns (bytes32);
}

contract GrannysMysteryBox {
    IDispensary private immutable dispensary;
    IHashGenerator private immutable hashGenerator;
    uint256 private immutable burnID;
    uint16[] private maxDroppable;
    uint16[] private dropped;
    uint256[] private tokenIds;
    uint256[] private autoDropTokenIds;
    uint256[] private dropRates;


    constructor(address _dispensary, address _hashGenerator, uint256 _burnID, uint256[] memory _tokenIds, uint256[] memory _autoDropTokenIds, uint256[] memory _dropRates, uint16[] memory _maxDroppable) {
        require(_tokenIds.length == _dropRates.length && _tokenIds.length == _maxDroppable.length, "ARRAY LENGTH MISMATCH");
        uint256 sum = 0;
        for (uint256 i = 0; i < _dropRates.length; i++) {
            sum += _dropRates[i];
        }
        require(sum == 2**256 - 1, "Sum of drop rates does not equal MAX_INT");

        dispensary = IDispensary(_dispensary);
        hashGenerator = IHashGenerator(_hashGenerator);
        burnID = _burnID;
        tokenIds = _tokenIds;
        autoDropTokenIds = _autoDropTokenIds;
        dropRates = _dropRates;
        maxDroppable = _maxDroppable;
        dropped = new uint16[](_tokenIds.length);
    }

    function getNextRandomHash(uint256 seed, uint256 index, uint256 rotation, uint256 hash) internal pure returns (uint256) {
        //Rotates the given hash around the uint256 bytespace given a rotation value
        //XOR with the current value of the hash to get a continuous stream of new values
        unchecked {
            uint256 rotation_mod = ((rotation * index) % 256);
            return (seed << rotation_mod | seed >> (256 - rotation_mod)) ^ hash;
        }
    }


    //Gas optimization: https://0xmacro.com/blog/solidity-gas-optimizations-cheat-sheet/
    function burn(uint16 amount) external {
        require(amount > 0, "You can't burn 0 tokens");
        //burn the token, will only succeed if the msg.sender has a sufficient amount of burnID in their wallet
        dispensary.safeBurn(msg.sender, burnID, amount);


        //Local Variable initialization
        uint16 leftover;
        uint16 delta;
        //Generate the random hash
        uint256 seed = uint256(hashGenerator.generateHash(amount));
        uint256 hash;
        uint256 rotation;

        //SLOAD optimization
        uint16[] memory _dropped = dropped;
        uint16[] memory _maxDroppable = maxDroppable;
        uint16[] memory dropping = new uint16[](_maxDroppable.length);
        uint256[] memory _tokenIds = autoDropTokenIds;
        //Drop all of the tokenIds that have a 100% drop rate
        for (uint256 i = 0; i < _tokenIds.length;) {
            dispensary.safeMint(msg.sender, _tokenIds[i], amount, '');
            unchecked {
                i++;
            }
        }
        _tokenIds = tokenIds;
        uint256[] memory _dropRates = dropRates;


        unchecked {
            //Select which tokenId should be won based off of a given hash from 0 -> uint256_MAX_INT
            for (uint256 j = 0; j < amount; j++) {
                rotation = seed>>((hash % 32) * 8);
                hash = getNextRandomHash(seed, j, rotation, hash);
                for (uint256 i = 0; i < _tokenIds.length; i++) {
                    if (hash <= _dropRates[i]) {
                        dropping[i]++;
                        break;
                    } else {
                        hash -= _dropRates[i];
                    }
                }
            }
            //Mint won tokens, if the tokens won exceeds the maxDroppable then add the remainder to the leftover value
            for (uint256 i = 0; i < _tokenIds.length; i++) {
                if (dropping[i] > 0) {
                    if (_maxDroppable[i] >= _dropped[i] + dropping[i]) {
                        dispensary.safeMint(msg.sender, _tokenIds[i], dropping[i], '');
                        _dropped[i] += dropping[i];
                    } else {
                        delta = _maxDroppable[i] - _dropped[i];
                        leftover += dropping[i] - delta;
                        if (delta > 0) {
                            dispensary.safeMint(msg.sender, _tokenIds[i], delta, '');
                            _dropped[i] += delta;
                        }
                    }
                }
            }
            //If the leftover value is not zero then assign the leftovers in the priority order of the tokenIds array if possible
            if (leftover > 0) {
                for (uint256 i = 0; i < _tokenIds.length; i++) {
                    if (_maxDroppable[i] > _dropped[i] && leftover > 0) {
                        if (_maxDroppable[i] >= _dropped[i] + leftover) {
                            dispensary.safeMint(msg.sender, _tokenIds[i], leftover, '');
                            _dropped[i] += leftover;
                            break;
                        } else {
                            delta = _maxDroppable[i] - _dropped[i];
                            dispensary.safeMint(msg.sender, _tokenIds[i], delta, '');
                            leftover -= delta;
                            _dropped[i] += delta;
                        }
                    }
                }
            }
        }
        dropped = _dropped;
    }
}