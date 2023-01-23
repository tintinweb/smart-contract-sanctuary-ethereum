/**
 *Submitted for verification at Etherscan.io on 2023-01-23
*/

// File: contracts/ChainPhallusErrors.sol




pragma solidity 0.8.7;

// Sale
error SaleNotOpen();
error NotPreSaleStage();
error NotMainSaleStage();
error SaleNotComplete();
error MainSaleNotComplete();
error AlreadyClaimed();
error InvalidClaimValue();
error InvalidClaimAmount();
error InvalidProof();
error InvalidMintValue();

// NFT
error NonExistentToken();

// Reveal
error InvalidReveal();
error BalanceNotWithdrawn();
error BalanceAlreadyWithdrawn();

// Arena
error LeavingProhibited();
error ArenaIsActive();
error ArenaNotActive();
error ArenaEntryClosed();
error WienersNotFluffy();
error WienersAreFluffy();
error LastErectWiener();
error GameOver();
error InvalidJoinCount();
error NotYourWiener();
// File: @openzeppelin/[email protected]/utils/cryptography/MerkleProof.sol


// OpenZeppelin Contracts (last updated v4.7.0) (utils/cryptography/MerkleProof.sol)

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Tree proofs.
 *
 * The proofs can be generated using the JavaScript library
 * https://github.com/miguelmota/merkletreejs[merkletreejs].
 * Note: the hashing algorithm should be keccak256 and pair sorting should be enabled.
 *
 * See `test/utils/cryptography/MerkleProof.test.js` for some examples.
 *
 * WARNING: You should avoid using leaf values that are 64 bytes long prior to
 * hashing, or use a hash function other than keccak256 for hashing leaves.
 * This is because the concatenation of a sorted pair of internal nodes in
 * the merkle tree could be reinterpreted as a leaf value.
 */
library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProof(proof, leaf) == root;
    }

    /**
     * @dev Calldata version of {verify}
     *
     * _Available since v4.7._
     */
    function verifyCalldata(
        bytes32[] calldata proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProofCalldata(proof, leaf) == root;
    }

    /**
     * @dev Returns the rebuilt hash obtained by traversing a Merkle tree up
     * from `leaf` using `proof`. A `proof` is valid if and only if the rebuilt
     * hash matches the root of the tree. When processing the proof, the pairs
     * of leafs & pre-images are assumed to be sorted.
     *
     * _Available since v4.4._
     */
    function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            computedHash = _hashPair(computedHash, proof[i]);
        }
        return computedHash;
    }

    /**
     * @dev Calldata version of {processProof}
     *
     * _Available since v4.7._
     */
    function processProofCalldata(bytes32[] calldata proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            computedHash = _hashPair(computedHash, proof[i]);
        }
        return computedHash;
    }

    /**
     * @dev Returns true if the `leaves` can be proved to be a part of a Merkle tree defined by
     * `root`, according to `proof` and `proofFlags` as described in {processMultiProof}.
     *
     * _Available since v4.7._
     */
    function multiProofVerify(
        bytes32[] memory proof,
        bool[] memory proofFlags,
        bytes32 root,
        bytes32[] memory leaves
    ) internal pure returns (bool) {
        return processMultiProof(proof, proofFlags, leaves) == root;
    }

    /**
     * @dev Calldata version of {multiProofVerify}
     *
     * _Available since v4.7._
     */
    function multiProofVerifyCalldata(
        bytes32[] calldata proof,
        bool[] calldata proofFlags,
        bytes32 root,
        bytes32[] memory leaves
    ) internal pure returns (bool) {
        return processMultiProofCalldata(proof, proofFlags, leaves) == root;
    }

    /**
     * @dev Returns the root of a tree reconstructed from `leaves` and the sibling nodes in `proof`,
     * consuming from one or the other at each step according to the instructions given by
     * `proofFlags`.
     *
     * _Available since v4.7._
     */
    function processMultiProof(
        bytes32[] memory proof,
        bool[] memory proofFlags,
        bytes32[] memory leaves
    ) internal pure returns (bytes32 merkleRoot) {
        // This function rebuild the root hash by traversing the tree up from the leaves. The root is rebuilt by
        // consuming and producing values on a queue. The queue starts with the `leaves` array, then goes onto the
        // `hashes` array. At the end of the process, the last hash in the `hashes` array should contain the root of
        // the merkle tree.
        uint256 leavesLen = leaves.length;
        uint256 totalHashes = proofFlags.length;

        // Check proof validity.
        require(leavesLen + proof.length - 1 == totalHashes, "MerkleProof: invalid multiproof");

        // The xxxPos values are "pointers" to the next value to consume in each array. All accesses are done using
        // `xxx[xxxPos++]`, which return the current value and increment the pointer, thus mimicking a queue's "pop".
        bytes32[] memory hashes = new bytes32[](totalHashes);
        uint256 leafPos = 0;
        uint256 hashPos = 0;
        uint256 proofPos = 0;
        // At each step, we compute the next hash using two values:
        // - a value from the "main queue". If not all leaves have been consumed, we get the next leaf, otherwise we
        //   get the next hash.
        // - depending on the flag, either another value for the "main queue" (merging branches) or an element from the
        //   `proof` array.
        for (uint256 i = 0; i < totalHashes; i++) {
            bytes32 a = leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++];
            bytes32 b = proofFlags[i] ? leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++] : proof[proofPos++];
            hashes[i] = _hashPair(a, b);
        }

        if (totalHashes > 0) {
            return hashes[totalHashes - 1];
        } else if (leavesLen > 0) {
            return leaves[0];
        } else {
            return proof[0];
        }
    }

    /**
     * @dev Calldata version of {processMultiProof}
     *
     * _Available since v4.7._
     */
    function processMultiProofCalldata(
        bytes32[] calldata proof,
        bool[] calldata proofFlags,
        bytes32[] memory leaves
    ) internal pure returns (bytes32 merkleRoot) {
        // This function rebuild the root hash by traversing the tree up from the leaves. The root is rebuilt by
        // consuming and producing values on a queue. The queue starts with the `leaves` array, then goes onto the
        // `hashes` array. At the end of the process, the last hash in the `hashes` array should contain the root of
        // the merkle tree.
        uint256 leavesLen = leaves.length;
        uint256 totalHashes = proofFlags.length;

        // Check proof validity.
        require(leavesLen + proof.length - 1 == totalHashes, "MerkleProof: invalid multiproof");

        // The xxxPos values are "pointers" to the next value to consume in each array. All accesses are done using
        // `xxx[xxxPos++]`, which return the current value and increment the pointer, thus mimicking a queue's "pop".
        bytes32[] memory hashes = new bytes32[](totalHashes);
        uint256 leafPos = 0;
        uint256 hashPos = 0;
        uint256 proofPos = 0;
        // At each step, we compute the next hash using two values:
        // - a value from the "main queue". If not all leaves have been consumed, we get the next leaf, otherwise we
        //   get the next hash.
        // - depending on the flag, either another value for the "main queue" (merging branches) or an element from the
        //   `proof` array.
        for (uint256 i = 0; i < totalHashes; i++) {
            bytes32 a = leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++];
            bytes32 b = proofFlags[i] ? leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++] : proof[proofPos++];
            hashes[i] = _hashPair(a, b);
        }

        if (totalHashes > 0) {
            return hashes[totalHashes - 1];
        } else if (leavesLen > 0) {
            return leaves[0];
        } else {
            return proof[0];
        }
    }

    function _hashPair(bytes32 a, bytes32 b) private pure returns (bytes32) {
        return a < b ? _efficientHash(a, b) : _efficientHash(b, a);
    }

    function _efficientHash(bytes32 a, bytes32 b) private pure returns (bytes32 value) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
    }
}

// File: @openzeppelin/[email protected]/utils/Strings.sol


// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// File: contracts/ChainPhallusRenderer.sol



pragma solidity 0.8.7;


contract ChainPhallusRenderer {
    using Strings for uint256;

    // Rendering constants
    string[13] public ballsArray = [unicode"8", unicode"ō", unicode"B", unicode"₿", unicode"β", unicode"З", unicode"$", unicode"𑂈", unicode"𐋀", unicode"Ӡ", unicode"θ", unicode"Ƀ", unicode"Ѯ"];
    string[21] public shaft1Array = [unicode"=", unicode"Ξ", unicode"⇔", unicode"⁐", unicode"÷", unicode"—", unicode"+", unicode"‡", unicode"∺", unicode"ǂ", unicode"―", unicode"–", unicode"∷", unicode"⋍", unicode"⇌", unicode"⎓", unicode"⟾", unicode"⏔", unicode"⏕", unicode"≂", unicode"≃"];
    string[21] public shaft2Array = [unicode"=", unicode"Ξ", unicode"⇔", unicode"⁐", unicode"÷", unicode"—", unicode"+", unicode"‡", unicode"∺", unicode"ǂ", unicode"―", unicode"–", unicode"∷", unicode"⋍", unicode"⇌", unicode"⎓", unicode"⟾", unicode"⏔", unicode"⏕", unicode"≂", unicode"≃"];
    string[19] public headArray = [unicode"D", unicode"Ͽ", unicode"Ͻ", unicode"Đ", unicode"Э", unicode">", unicode"Ӭ", unicode"O", unicode"∋", unicode"Ӛ", unicode"Ә", unicode"»", unicode"Ѳ", unicode"Ӫ", unicode"Θ", unicode"Ɗ", unicode"Ø", unicode"Þ", unicode"⊃"];
    string[11] public jizzArray = [unicode"~", unicode"—", unicode"–", unicode"―", unicode"¬", unicode"⌐", unicode"⁊", unicode"√", unicode"ᜯ", unicode"ᜰ", unicode"∖"];


    uint256[21] rarityArray = [0, 2, 5, 9, 14, 20, 27, 35, 44, 54, 65, 77, 90, 104, 119, 135, 152, 170, 189, 209, 230]; // , 252];

    uint256[10][] ancients;

    // Mapping to determine pulledOut status for the metadata
    mapping(uint256 => bool) public pulledOut;
    // Mapping to determine champion status for the metadata
    mapping(uint256 => bool) public wienerOfWieners;


    constructor() {
        ancients.push([0, 0, 0, 0, 0]);
        ancients.push([1, 1, 1, 1, 1]);
        ancients.push([2, 2, 2, 2, 2]);
        ancients.push([3, 3, 3, 3, 3]);
        ancients.push([4, 4, 4, 4, 4]);
        ancients.push([5, 5, 5, 5, 5]);
        ancients.push([6, 6, 6, 6, 6]);
        ancients.push([7, 7, 7, 7, 7]);
        ancients.push([8, 8, 8, 8, 8]);
        ancients.push([9, 9, 9, 9, 9]);
    }
    // Get ChainPhallus address
    address _chainPhallusAddress;
    function receiveChainPhallusAddress(address chainPhallusAddress) public {
        _chainPhallusAddress = chainPhallusAddress;
    }
    // TODO: modify selectors and symmetry calculation
    function getBalls(uint256 id, uint256 seed) public view returns (string memory) {
        if (id < ancients.length) {
            return ballsArray[ancients[id][0]];
        }

        uint256 raritySelector = seed % 104;

        uint256 charSelector = 0;

        for (uint i = 0; i < 13; i++) {
            if (raritySelector >= rarityArray[i]) {
                charSelector = i;
            }
        }

        return ballsArray[charSelector];
    }

    function getShaft1(uint256 id, uint256 seed) public view returns (string memory) {
        if (id < ancients.length) {
            return shaft1Array[ancients[id][1]];
        }

        uint256 raritySelector = seed % 252;

        uint256 charSelector = 0;

        for (uint i = 0; i < 21; i++) {
            if (raritySelector >= rarityArray[i]) {
                charSelector = i;
            }
        }

        return shaft1Array[charSelector];
    }

    function getShaft2(uint256 id, uint256 seed) public view returns (string memory) {
        if (id < ancients.length) {
            return shaft2Array[ancients[id][2]];
        }

        uint256 raritySelector = uint256(keccak256(abi.encodePacked(seed))) % 252;

        uint256 charSelector = 0;

        for (uint i = 0; i < 21; i++) {
            if (raritySelector >= rarityArray[i]) {
                charSelector = i;
            }
        }

        return shaft2Array[charSelector];
    }

    function getHead(uint256 id, uint256 seed) public view returns (string memory) {
        if (id < ancients.length) {
            return headArray[ancients[id][3]];
        }

        uint256 raritySelector = seed % 209;

        uint256 charSelector = 0;

        for (uint i = 0; i < 19; i++) {
            if (raritySelector >= rarityArray[i]) {
                charSelector = i;
            }
        }

        return headArray[charSelector];
    }

    function getJizz(uint256 id, uint256 seed) public view returns (string memory) {
        if (id < ancients.length) {
            return jizzArray[ancients[id][4]];
        }

        uint256 raritySelector = seed % 77;

        uint256 charSelector = 0;

        for (uint i = 0; i < 11; i++) {
            if (raritySelector >= rarityArray[i]) {
                charSelector = i;
            }
        }

        return jizzArray[charSelector];
    }

    function setPulledOutStatus(uint256 id) external {
        pulledOut[id] = true;
    }
    function setWienerOfWienersStatus(uint256 id) external {
        wienerOfWieners[id] = true;
    }

    function getStatus(uint256 id, address owner) public view returns (string memory) {
        if (owner == _chainPhallusAddress) {
            return "Swingin\'";
        }
        if (pulledOut[id]) {
            return "Pulled out";
        }
        if (wienerOfWieners[id]) {
            return "Wiener";
        }
        return "Virgin";
    }

    function assemblePhallus(bool revealComplete, uint256 id, uint256 seed) public view returns (string memory phallus) {
        if (!revealComplete) {
            return '8==D~';
        }

        return string(abi.encodePacked(
                getBalls(id, seed),
                getShaft1(id, seed),
                getShaft2(id, seed),
                getHead(id, seed),
                getJizz(id, seed)
            ));
    }

    function calculateGolfScore(uint256 id, uint256 seed) public view returns (uint256) {
        if (id < ancients.length) {
            return 0;
        }

        uint256 ballsRarity = seed % 104;
        uint256 shaft1Rarity = seed % 252;
        uint256 shaft2Rarity = uint256(keccak256(abi.encodePacked(seed))) % 252;
        uint256 headRarity = seed % 209;
        uint256 jizzRarity = seed % 77;

        uint256 ballsGolf = 0;
        uint256 shaft1Golf = 0;
        uint256 shaft2Golf = 0;
        uint256 headGolf = 0;
        uint256 jizzGolf = 0;
        uint256 i = 0;

        for (i = 0; i < 13; i++) {
            if (ballsRarity >= rarityArray[i]) {
                ballsGolf = i;
            }
        }
        for (i = 0; i < 21; i++) {
            if (shaft1Rarity >= rarityArray[i]) {
                shaft1Golf = i;
            }
        }
        for (i = 0; i < 21; i++) {
            if (shaft2Rarity >= rarityArray[i]) {
                shaft2Golf = i;
            }
        }
        for (i = 0; i < 19; i++) {
            if (headRarity >= rarityArray[i]) {
                headGolf = i;
            }
        }
        for (i = 0; i < 11; i++) {
            if (jizzRarity >= rarityArray[i]) {
                jizzGolf = i;
            }
        }

        return ballsGolf + shaft1Golf + shaft2Golf + headGolf + jizzGolf;
    }

    function calculateSymmetry(uint256 id, uint256 seed) public view returns (string memory) {

        uint256 symCount = 0;

        if (id < ancients.length) {
            symCount = 1;
        } else {
            uint256 shaft1Rarity = seed % 252;
            uint256 shaft2Rarity = uint256(keccak256(abi.encodePacked(seed))) % 252;

            uint256 shaft1Index = 0;
            uint256 shaft2Index = 0;
            uint256 i = 0;

            for (i = 0; i < 21; i++) {
                if (shaft1Rarity >= rarityArray[i]) {
                    shaft1Index = i;
                }
            }
            for (i = 0; i < 21; i++) {
                if (shaft2Rarity >= rarityArray[i]) {
                    shaft2Index = i;
                }
            }
            if (shaft1Index == shaft2Index) {
                symCount =  1;
            }
        }
        if (symCount == 1) {
            return "Perfect Shaft";
        }
        else {
            return "Crooked Shaft";
        }
    }

    function getTextColor(uint256 id) public view returns (string memory) {
        if (id < ancients.length) {
            return 'RGB(148,256,209)';
        } else {
            return 'RGB(0,0,0)';
        }
    }

    function getBackgroundColor(uint256 id, uint256 seed) public view returns (string memory){
        if (id < ancients.length) {
            return 'RGB(128,128,128)';
        }

        uint256 golf = calculateGolfScore(id, seed);
        uint256 red;
        uint256 green;
        uint256 blue;

        if (golf >= 56) {
            red = 255;
            green = 255;
            blue = 255 - (golf - 56) * 4;
        }
        else {
            red = 255 - (56 - golf) * 4;
            green = 255 - (56 - golf) * 4;
            blue = 255;
        }

        return string(abi.encodePacked("RGB(", red.toString(), ",", green.toString(), ",", blue.toString(), ")"));
    }
    string constant headerText = 'data:application/json;ascii,{"description": "ChainPhallus Arena; where you go sword to sword until you are crowned the wiener.","image":"data:image/svg+xml;base64,';
    string constant attributesText = '","attributes":[{"trait_type":"Golf Score","value":';
    string constant symmetryText = '},{"trait_type":"Shaft","value":"';
    string constant ballsText = '"},{"trait_type":"Balls","value":"';
    string constant shaft1Text = '"},{"trait_type":"Lower Shaft","value":"';
    string constant shaft2Text = '"},{"trait_type":"Upper Shaft","value":"';
    string constant headText = '"},{"trait_type":"Head","value":"';
    string constant jizzText = '"},{"trait_type":"Jizz","value":"';
    string constant statusText = '"},{"trait_type":"Status","value":"';
    string constant arenaDurationText = '"},{"trait_type":"Arena Score","value":';
    string constant ancientText = '},{"trait_type":"Ancient","value":"';
    string constant footerText = '"}]}';

    function renderMetadata(bool revealComplete, uint256 id, uint256 seed, uint256 arenaDuration, address owner) external view returns (string memory) {
        if (!revealComplete) {
            return preRevealMetadata();
        }

        uint256 golfScore = calculateGolfScore(id, seed);

        string memory svg = b64Encode(bytes(renderSvg(true, id, seed, arenaDuration, owner)));

        string memory attributes = string(abi.encodePacked(attributesText, golfScore.toString()));
        attributes = string(abi.encodePacked(attributes, symmetryText, calculateSymmetry(id, seed)));
        attributes = string(abi.encodePacked(attributes, ballsText, getBalls(id, seed)));
        attributes = string(abi.encodePacked(attributes, shaft1Text, getShaft1(id, seed)));
        attributes = string(abi.encodePacked(attributes, shaft2Text, getShaft2(id, seed)));
        attributes = string(abi.encodePacked(attributes, headText, getHead(id, seed)));
        attributes = string(abi.encodePacked(attributes, jizzText, getJizz(id, seed)));
        attributes = string(abi.encodePacked(attributes, statusText, getStatus(id, owner)));
        attributes = string(abi.encodePacked(attributes, arenaDurationText, arenaDuration.toString()));

        if (id < ancients.length) {
            attributes = string(abi.encodePacked(attributes, ancientText, 'Ancient'));
        } else {
            attributes = string(abi.encodePacked(attributes, ancientText, 'Not Ancient'));
        }

        attributes = string(abi.encodePacked(attributes, footerText));

        return string(abi.encodePacked(headerText, svg, attributes));
    }

    string constant svg1 = "<svg xmlns='http://www.w3.org/2000/svg' width='400' height='400' style='background-color:";
    string constant svg2 = "'>  <filter id='noise'> <feTurbulence type='turbulence' baseFrequency='0.0024' numOctaves='8' result='turbulence' /> <feDisplacementMap in='SourceGraphic' scale='42' /> </filter>";
    string constant svg3 = "<text style='filter: url(#noise)' x='50%' y='50%' dominant-baseline='middle' text-anchor='middle' font-size='75px' fill='";
    string constant svg4 = "'>";
    string constant svg5 = "</text></svg>";

    function renderSvg(bool revealComplete, uint256 id, uint256 seed, uint256 arenaDuration, address owner) public view returns (string memory) {
        if (!revealComplete) {
            return preRevealSvg();
        }

        string memory phallus = assemblePhallus(true, id, seed);
        string memory pubes;

        if (arenaDuration > 0) {
            pubes = generatePubes(arenaDuration, seed);
        }

        return string(abi.encodePacked(svg1, getBackgroundColor(id, seed), svg2, pubes, svg3, getTextColor(id), svg4, phallus, svg5));
    }

    string constant pubeSymbol = "<symbol id='pube'><g stroke='RGBA(0,0,0,1)'><text x='40' y='40' dominant-baseline='middle' text-anchor='middle' font-weight='normal' font-size='36px' fill='RGBA(0,0,0,1)'>&#x04A8</text></g></symbol>";
    string constant pubePlacement1 = "<g transform='translate(";
    string constant pubePlacement2 = ") scale(";
    string constant pubePlacement3 = ") rotate(";
    string constant pubePlacement4 = ")'><use href='#pube'/></g>";

    function generatePubes(uint256 arenaDuration, uint256 seed) internal pure returns (string memory) {
        string memory pubes;
        string memory pubesTemp;

        uint256 count = arenaDuration / 10;

        if (count > 500) {
            count = 500;
        }

        for (uint256 i = 0; i < count; i++) {
            string memory pube;

            uint256 pubeSeed = uint256(keccak256(abi.encodePacked(seed, i)));

            uint256 scale1 = pubeSeed % 2;
            uint256 scale2 = pubeSeed % 5;
            if (scale1 == 0) {
                scale2 += 5;
            }
            uint256 xShift = pubeSeed % 332;
            uint256 yShift = pubeSeed % 354;
            int256 rotate = int256(pubeSeed % 91) - 45;

            pube = string(abi.encodePacked(pube, pubePlacement1, xShift.toString(), " ", yShift.toString(), pubePlacement2, scale1.toString(), ".", scale2.toString()));

            if (rotate >= 0) {
                pube = string(abi.encodePacked(pube, pubePlacement3, uint256(rotate).toString(), pubePlacement4));
            } else {
                pube = string(abi.encodePacked(pube, pubePlacement3, "-", uint256(0 - rotate).toString(), pubePlacement4));
            }

            pubesTemp = string(abi.encodePacked(pubesTemp, pube));

            if (i % 10 == 0) {
                pubes = string(abi.encodePacked(pubes, pubesTemp));
                pubesTemp = "";
            }
        }

        return string(abi.encodePacked(pubeSymbol, pubes, pubesTemp));
    }

    function preRevealMetadata() internal pure returns (string memory) {
        string memory JSON;
        string memory svg = preRevealSvg();
        JSON = string(abi.encodePacked('data:application/json;ascii,{"description": "ChainPhallus Arena; where you go sword to sword until you are crowned the wiener.","image":"data:image/svg+xml;base64,', b64Encode(bytes(svg)), '"}'));
        return JSON;
    }

    function preRevealSvg() internal pure returns (string memory) {
        return "<svg xmlns='http://www.w3.org/2000/svg' width='400' height='400' style='background-color:RGB(255,255,255);'><text x='50%' y='50%' dominant-baseline='middle' text-anchor='middle' font-size='75px'>?????</text></svg>";
    }

    string constant private TABLE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';

    function b64Encode(bytes memory _data) internal pure returns (string memory result) {
        if (_data.length == 0) return '';
        string memory _table = TABLE;
        uint256 _encodedLen = 4 * ((_data.length + 2) / 3);
        result = new string(_encodedLen + 32);

        assembly {
            mstore(result, _encodedLen)
            let tablePtr := add(_table, 1)
            let dataPtr := _data
            let endPtr := add(dataPtr, mload(_data))
            let resultPtr := add(result, 32)

            for {} lt(dataPtr, endPtr) {}
            {
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)
                mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(18, input), 0x3F)))))
                resultPtr := add(resultPtr, 1)
                mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(12, input), 0x3F)))))
                resultPtr := add(resultPtr, 1)
                mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(6, input), 0x3F)))))
                resultPtr := add(resultPtr, 1)
                mstore(resultPtr, shl(248, mload(add(tablePtr, and(input, 0x3F)))))
                resultPtr := add(resultPtr, 1)
            }
            switch mod(mload(_data), 3)
            case 1 {mstore(sub(resultPtr, 2), shl(240, 0x3d3d))}
            case 2 {mstore(sub(resultPtr, 1), shl(248, 0x3d))}
        }
        return result;
    }
}
// File: @openzeppelin/[email protected]/utils/Context.sol


// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// File: @openzeppelin/[email protected]/access/Ownable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;


/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// File: @openzeppelin/[email protected]/utils/Address.sol


// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly
                /// @solidity memory-safe-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// File: @openzeppelin/[email protected]/token/ERC721/IERC721Receiver.sol


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// File: @openzeppelin/[email protected]/utils/introspection/IERC165.sol


// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// File: @openzeppelin/[email protected]/utils/introspection/ERC165.sol


// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;


/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// File: @openzeppelin/[email protected]/token/ERC721/IERC721.sol


// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;


/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// File: @openzeppelin/[email protected]/token/ERC721/extensions/IERC721Enumerable.sol


// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;


/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// File: @openzeppelin/[email protected]/token/ERC721/extensions/IERC721Metadata.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;


/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// File: @openzeppelin/[email protected]/token/ERC721/ERC721.sol


// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;








/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: address zero is not a valid owner");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: invalid token ID");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overridden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not token owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        _requireMinted(tokenId);

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");
        _safeTransfer(from, to, tokenId, data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits an {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits an {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Reverts if the `tokenId` has not been minted yet.
     */
    function _requireMinted(uint256 tokenId) internal view virtual {
        require(_exists(tokenId), "ERC721: invalid token ID");
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    /// @solidity memory-safe-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

// File: @openzeppelin/[email protected]/token/ERC721/extensions/ERC721Enumerable.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/ERC721Enumerable.sol)

pragma solidity ^0.8.0;



/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract ERC721Enumerable is ERC721, IERC721Enumerable {
    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721Enumerable.totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = ERC721.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }
}

// File: contracts/ChainPhallus.sol



pragma solidity 0.8.7;







contract ChainPhallus is ERC721, ERC721Enumerable, Ownable {

    /*************************
     COMMON
     *************************/

    // Sale stage enum
    enum Stage {
        STAGE_COMPLETE,  // 0
        STAGE_PRESALE,  // 1
        STAGE_MAIN_SALE // 2
    }

    bool balanceNotWithdrawn;

    constructor(uint256 _secretCommit, address _renderer, bytes32 _merkleRoot) ERC721("ChainPhallus Arena", unicode"8==D~")  {
        // tokenLimit = _tokenLimit;
        secret = _secretCommit;
        merkleRoot = _merkleRoot;
        balanceNotWithdrawn = true;

        // Start in presale stage
        stage = Stage.STAGE_PRESALE;

        renderer = ChainPhallusRenderer(_renderer);

        // Send address to renderer
        renderer.receiveChainPhallusAddress(address(this));

        // Mint ancients
        for (uint256 i = 0; i < 10;) {
            _createPhallus();
            unchecked{ i++; }
        }
    }

    fallback() external payable {}

    /*************************
     TOKEN SALE
     *************************/

    Stage public               stage;
    uint256 public             saleEnds;

    // Merkle distributor values
    bytes32 immutable merkleRoot;
    mapping(uint256 => uint256) private claimedBitMap;
    uint256 public constant saleLength = 69 hours;
    uint256 public constant salePrice = 0.025 ether;

    uint256 secret;             // Entropy supplied by owner (commit/reveal style)
    uint256 userSecret;         // Pseudorandom entropy provided by minters

    // -- MODIFIERS --

    modifier onlyMainSaleOpen() {
        if (stage != Stage.STAGE_MAIN_SALE || mainSaleComplete()) {
            revert SaleNotOpen();
        }
        _;
    }

    modifier onlyPreSale() {
        if (stage != Stage.STAGE_PRESALE) {
            revert NotPreSaleStage();
        }
        _;
    }

    modifier onlyMainSale() {
        if (stage != Stage.STAGE_MAIN_SALE) {
            revert NotMainSaleStage();
        }
        _;
    }

    modifier onlySaleComplete() {
        if (stage != Stage.STAGE_COMPLETE) {
            revert SaleNotComplete();
        }
        _;
    }

    // -- VIEW METHODS --

    function mainSaleComplete() public view returns (bool) {
        return block.timestamp >= saleEnds;  // || totalSupply() == tokenLimit;
    }

    function isClaimed(uint256 index) public view returns (bool) {
        uint256 claimedWordIndex = index / 256;
        uint256 claimedBitIndex = index % 256;
        uint256 claimedWord = claimedBitMap[claimedWordIndex];
        uint256 mask = (1 << claimedBitIndex);
        return claimedWord & mask == mask;
    }

    // -- OWNER METHODS --

    // Reveal the wieners
    function theGreatReveal(uint256 _secretReveal) external onlyOwner onlyMainSale {
        if (!mainSaleComplete()) {
            revert MainSaleNotComplete();
        }

        if (uint256(keccak256(abi.encodePacked(_secretReveal))) != secret) {
            revert InvalidReveal();
        }

        // Final secret is XOR between the pre-committed secret and the pseudo-random user contributed salt
        secret = _secretReveal ^ userSecret;

        // Won't be needing this anymore
        delete userSecret;

        stage = Stage.STAGE_COMPLETE;
    }

    // Start main sale
    function startMainSale() external onlyOwner onlyPreSale {
        stage = Stage.STAGE_MAIN_SALE;
        saleEnds = block.timestamp + saleLength;
    }

    // Withdraw sale proceeds
    function withdraw() external onlyOwner {
        // Owner can't reneg on bounty
        if (arenaActive()) {
            revert ArenaIsActive();
        }
        // Can only withdraw once, and only a fixed percentage
        if (!balanceNotWithdrawn) {
            revert BalanceAlreadyWithdrawn();
        }
        balanceNotWithdrawn = false;
        owner().call{value : address(this).balance * 3058 / 10000}("");
    }

    // -- USER METHODS --

    function claim(uint256 _index, uint256 _ogAmount, uint256 _wlAmount, bytes32[] calldata _merkleProof, uint256 _amount) external payable onlyPreSale {
        // Ensure not already claimed
        if (isClaimed(_index)) {
            revert AlreadyClaimed();
        }

        // Prevent accidental claim of 0
        if (_amount == 0) {
            revert InvalidClaimAmount();
        }

        // Check claim amount
        uint256 total = _ogAmount + _wlAmount;
        if (_amount > total) {
            revert InvalidClaimAmount();
        }

        // Check claim value
        uint256 paidClaims = 0;
        if (_amount > _ogAmount) {
            paidClaims = _amount - _ogAmount;
        }
        if (msg.value < paidClaims * salePrice) {
            revert InvalidClaimValue();
        }

        // Verify the merkle proof
        bytes32 node = keccak256(abi.encodePacked(_index, msg.sender, _ogAmount, _wlAmount));
        if (!MerkleProof.verify(_merkleProof, merkleRoot, node)) {
            revert InvalidProof();
        }

        // Mark it claimed and mint
        _setClaimed(_index);

        for (uint256 i = 0; i < _amount; i++) {
            _createPhallus();
        }

        _mix();
    }

    // Mint wieners
    function createPhallus() external payable onlyMainSaleOpen {
        uint256 count = msg.value / salePrice;

        if (count == 0) {
            revert InvalidMintValue();
        } else if (count > 20) {
            count = 20;
        }

        // Mint 'em
        for (uint256 i = 0; i < count;) {
            _createPhallus();
            unchecked{ i++; }
        }

        _mix();

        // Send any excess ETH back to the caller
        uint256 excess = msg.value - (salePrice * count);
        if (excess > 0) {
            (bool success,) = msg.sender.call{value : excess}("");
            require(success);
        }
    }

    // -- INTERNAL METHODS --

    function _setClaimed(uint256 index) internal {
        uint256 claimedWordIndex = index / 256;
        uint256 claimedBitIndex = index % 256;
        claimedBitMap[claimedWordIndex] = claimedBitMap[claimedWordIndex] | (1 << claimedBitIndex);
    }

    function _createPhallus() internal {
        uint256 tokenId = totalSupply();
        _mint(msg.sender, tokenId);
    }

    function _mix() internal {
        // Add some pseudorandom value which will be mixed with the pre-committed secret
        unchecked {
            userSecret += uint256(blockhash(block.number - 1));
        }
    }

    /*************************
     NFT
     *************************/

    modifier onlyTokenExists(uint256 _id) {
        if (!_exists(_id)) {
            revert NonExistentToken();
        }
        _;
    }

    ChainPhallusRenderer public renderer;

    // -- VIEW METHODS --

    function assemblePhallus(uint256 _id) external view onlyTokenExists(_id) returns (string memory) {
        return renderer.assemblePhallus(stage == Stage.STAGE_COMPLETE, _id, getFinalizedSeed(_id));
    }

    function tokenURI(uint256 _id) public view override onlyTokenExists(_id) returns (string memory) {
        return renderer.renderMetadata(stage == Stage.STAGE_COMPLETE, _id, getFinalizedSeed(_id), roundsSurvived[_id], ownerOf(_id));
    }

    function renderSvg(uint256 _id) external view onlyTokenExists(_id) returns (string memory) {
        uint256 rounds;

        // If wiener is still in the arena, show them with correct amount of scars
        if (ownerOf(_id) == address(this)) {
            rounds = currentRound;
        } else {
            rounds = roundsSurvived[_id];
        }

        return renderer.renderSvg(stage == Stage.STAGE_COMPLETE, _id, getFinalizedSeed(_id), rounds, ownerOf(_id));
    }

    // -- INTERNAL METHODS --

    function getFinalizedSeed(uint256 _tokenId) internal view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(secret, _tokenId)));
    }

    /*************************
     ARENA
     *************************/

    uint256     arenaOpenedBlock;
    uint256     wienersLastBust;
    uint256     champion;

    uint256 public currentRound = 0;
    uint256 public bustedNut = 0;
    uint256 public pulledOut = 0;
    uint256 public swingin = 0;

    uint256 public constant arenaWaitBlocks = 12600;
    uint256 public constant blocksPerRound = 42;

    mapping(uint256 => address) public wienerDepositor;
    mapping(uint256 => uint256) public roundsSurvived;

    // -- MODIFIERS --

    modifier onlyOpenArena() {
        if (!entryOpen()) {
            revert ArenaEntryClosed();
        }
        _;
    }

    // -- VIEW METHODS --

    struct ArenaInfo {
        uint256 busted;
        uint256 swingin;
        uint256 pulledOut;
        uint256 currentRound;
        uint256 bounty;
        uint256 hardness;
        uint256 nextBust;
        uint256 champion;
        uint256 entryClosedBlock;
        bool horny;
        bool open;
        bool active;
        bool gameOver;
    }

    function arenaInfo() external view returns (ArenaInfo memory info) {
        info.busted = bustedNut;
        info.swingin = swingin;
        info.pulledOut = pulledOut;
        info.currentRound = currentRound;
        info.bounty = address(this).balance;
        info.hardness = howHornyAreTheWieners();
        info.champion = champion;
        info.entryClosedBlock = entryClosedBlock();

        if (!theWienersAreFluffy()) {
            info.nextBust = wienersLastBust + blocksPerRound - block.number;
        }

        info.horny = theWienersAreFluffy();
        info.open = entryOpen();
        info.active = arenaActive();
        info.gameOver = block.number > info.entryClosedBlock && info.swingin <= 1;
    }

    // Return array of msg.senders remaining wieners
    function myWieners() external view returns (uint256[] memory) {
        return ownerWieners(msg.sender);
    }

    // Return array of owner's remaining wieners
    function ownerWieners(address _owner) public view returns (uint256[] memory) {
        address holdingAddress;
        holdingAddress = address(this);

        uint256 total = balanceOf(holdingAddress);
        uint256[] memory wieners = new uint256[](total);

        uint256 index = 0;

        for (uint256 i = 0; i < total; i++) {
            uint256 id = tokenOfOwnerByIndex(holdingAddress, i);

            if (wienerDepositor[id] == _owner) {
                wieners[index++] = id;
            }
        }

        assembly {
            mstore(wieners, index)
        }

        return wieners;
    }

    function arenaActive() public view returns (bool) {
        return arenaOpenedBlock > 0;
    }

    function entryOpen() public view returns (bool) {
        return arenaActive() && block.number < entryClosedBlock();
    }

    function entryClosedBlock() public view returns (uint256) {
        return arenaOpenedBlock + arenaWaitBlocks;
    }

    function howHornyAreTheWieners() public view returns (uint256) {

        if (swingin == 0) {
            return 0;
        }

        uint256 hardness = 1;

        // Calculate how many wieners busted (0.2% of wieners > 1000)
        if (swingin >= 2000) {
            uint256 excess = swingin - 1000;
            hardness = excess / 500;
        }

        // The last wiener standing never busts
        if (hardness >= swingin) {
            hardness = swingin - 1;
        }

        // Generous upper bound to prevent gas overflow
        if (hardness > 50) {
            hardness = 50;
        }

        return hardness;
    }

    function theWienersAreFluffy() public view returns (bool) {
        return block.number >= wienersLastBust + blocksPerRound;
    }

    // -- OWNER METHODS --

    function openArena() external payable onlyOwner onlySaleComplete {
        if (arenaActive()) {
            revert ArenaIsActive();
        }
        if (balanceNotWithdrawn) {
            revert BalanceNotWithdrawn();
        }

        // Open the arena
        arenaOpenedBlock = block.number;
        wienersLastBust = block.number + arenaWaitBlocks;
    }

    // -- USER METHODS --

    // Can be called every `blocksPerRound` blocks to kill off some eager wieners
    function timeToBust() external {
        if (!arenaActive()) {
            revert ArenaNotActive();
        }
        if (!theWienersAreFluffy()) {
            revert WienersNotFluffy();
        }

        if (swingin == 1) {
            revert LastErectWiener();
        }
        if (swingin == 0) {
            revert GameOver();
        }

        // The blockhash of every `blocksPerRound` block is used to determine who busts
        uint256 entropyBlock;
        if (block.number - (wienersLastBust + blocksPerRound) > 255) {
            // If this method isn't called within 255 blocks of the period end, this is a fallback so we can still progress
            entropyBlock = (block.number / blocksPerRound) * blocksPerRound - 1;
        } else {
            // Use blockhash of every 42nd block
            entropyBlock = (wienersLastBust + blocksPerRound) - 1;
        }
        uint256 entropy = uint256(blockhash(entropyBlock));
        assert(entropy != 0);

        // Update state
        wienersLastBust = block.number;
        currentRound++;

        // Kill off a percentage of wieners
        uint256 killCounter = howHornyAreTheWieners();
        bytes memory buffer = new bytes(32);
        // i starts at 1 to prevent infinite loop
        for (uint256 i = 1; i <= killCounter;) {
            // Entropy must increase even if the kill doesn't count
            unchecked { entropy = entropy + i; }
            // Gas saving trick to avoid abi.encodePacked
            assembly { mstore(add(buffer, 32), entropy) }
            // Balance of contract in case tokens were transferred without joining
            uint256 whoDied = uint256(keccak256(buffer)) % balanceOf(address(this));
            // Go to your happy place, loser
            uint256 wienerToBust = tokenOfOwnerByIndex(address(this), whoDied);
            _burn(wienerToBust);
            // Check to ensure that busted wiener was participating in the arena
            if (wienerDepositor[wienerToBust] == address(0)) {
                // If not participating, kill doesn't count
                unchecked{ --i; }
            }
            else {
                // If participating, update counts
                // Clear state
                delete wienerDepositor[wienerToBust];
                bustedNut++;
                swingin--;
            }
            unchecked{ i++; }
        }

        // Record the champion
        if (swingin == 1) {
            // Check all tokens in contract until champion is found
            uint256 wienerToCheck;
            for (uint256 i = 0; i < balanceOf(address(this));) {
                wienerToCheck = tokenOfOwnerByIndex(address(this), i);
                if (wienerDepositor[wienerToCheck] != address(0)) {
                    // If token was participating in arena it must the the champion
                    champion = wienerToCheck;
                    break;
                }
                unchecked{ i++; }
            }
            // Record the champion's achievement
            roundsSurvived[champion] = currentRound;
            // Set status
            renderer.setWienerOfWienersStatus(champion);
            // Pay the champion's owner and return wiener
            payable(wienerDepositor[champion]).transfer(address(this).balance);
            _transfer(address(this), wienerDepositor[champion], champion);
        }
    }

    function joinArena(uint256 _tokenId) external onlyOpenArena {
        _joinArena(_tokenId);
    }

    function multiJoinArena(uint256[] memory _tokenIds) external onlyOpenArena {
        if (_tokenIds.length > 20) {
            revert InvalidJoinCount();
        }

        for (uint256 i; i < _tokenIds.length;) {
            _joinArena(_tokenIds[i]);
            unchecked{ i++; }
        }
    }

    function claimBounty(uint256 _tokenId) external {
        if (wienerDepositor[_tokenId] != msg.sender) {
            revert NotYourWiener();
        }

        // Can't leave arena if wieners are horny (unless it's the champ and the game is over)
        if (swingin != 1 && theWienersAreFluffy()) {
            revert WienersAreFluffy();
        }

        // Can't leave before a single round has passed
        uint256 round = currentRound;
        if (currentRound == 0) {
            revert LeavingProhibited();
        }

        // Record the wiener's achievement
        roundsSurvived[_tokenId] = round;

        // Clear state
        delete wienerDepositor[_tokenId];

        // Must burn NFT to claim bounty
        uint256 battleBounty = address(this).balance / swingin;
        _burn(_tokenId);
        bustedNut++;
        swingin--;
        payable(msg.sender).transfer(battleBounty);

        // If this was the second last wiener to leave, the last one left is the champ
        if (swingin == 1) {
            // Check all tokens in contract until champion is found
            uint256 wienerToCheck;
            for (uint256 i = 0; i < balanceOf(address(this));) {
                wienerToCheck = tokenOfOwnerByIndex(address(this), i);
                if (wienerDepositor[wienerToCheck] != address(0)) {
                    // If token was participating in arena it must the the champion
                    champion = wienerToCheck;
                    break;
                }
                unchecked{ i++; }
            }
            // Record the champion's achievement
            roundsSurvived[champion] = round;
            // Set status
            renderer.setWienerOfWienersStatus(champion);
            // Pay the champion's owner and return wiener
            payable(wienerDepositor[champion]).transfer(address(this).balance);
            _transfer(address(this), wienerDepositor[champion], champion);
        }
    }

    function leaveArena(uint256 _tokenId) external {
        if (wienerDepositor[_tokenId] != msg.sender) {
            revert NotYourWiener();
        }

        // Can't leave arena if wieners are horny (unless it's the champ and the game is over)
        if (swingin != 1 && theWienersAreFluffy()) {
            revert WienersAreFluffy();
        }

        // Can't leave before a single round has passed
        uint256 round = currentRound;
        if (currentRound == 0) {
            revert LeavingProhibited();
        }

        // Record the wiener's achievement
        roundsSurvived[_tokenId] = round;

        // Set status
        renderer.setPulledOutStatus(_tokenId);
        // Clear state
        delete wienerDepositor[_tokenId];

        // Return wiener
         _transfer(address(this), msg.sender, _tokenId);
        pulledOut++;
        swingin--;

        // If this was the second last wiener to leave, the last one left is the champ
        if (swingin == 1) {
            // Check all tokens in contract until champion is found
            uint256 wienerToCheck;
            for (uint256 i = 0; i < balanceOf(address(this));) {
                wienerToCheck = tokenOfOwnerByIndex(address(this), i);
                if (wienerDepositor[wienerToCheck] != address(0)) {
                    // If token was participating in arena it must the the champion
                    champion = wienerToCheck;
                    break;
                }
                unchecked{ i++; }
            }
            // Record the champion's achievement
            roundsSurvived[champion] = round;
            // Set status
            renderer.setWienerOfWienersStatus(champion);
            // Pay the champion's owner and return wiener
            payable(wienerDepositor[champion]).transfer(address(this).balance);
            _transfer(address(this), wienerDepositor[champion], champion);
        }
    }
    // -- INTERNAL METHODS --

    function _joinArena(uint256 _tokenId) internal {
        // Send wiener to the arena
        transferFrom(msg.sender, address(this), _tokenId);
        wienerDepositor[_tokenId] = msg.sender;
        swingin++;
    }

    /*************************
     MISC
     *************************/

    function onERC721Received(address, address, uint256, bytes memory) external pure returns (bytes4) {
        return this.onERC721Received.selector;
    }

    function _beforeTokenTransfer(address _from, address _to, uint256 _tokenId) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(_from, _to, _tokenId);
    }

    function supportsInterface(bytes4 _interfaceId) public view virtual override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(_interfaceId);
    }
}