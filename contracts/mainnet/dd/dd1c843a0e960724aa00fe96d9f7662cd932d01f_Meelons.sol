pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "./ERC721.sol";
import "./InitializableOwnable.sol";
import "./Address.sol";

contract Meelons is ERC721, InitializableOwnable {
    using Address for address;

    uint256 private _totalSupply = 10000;
    uint256 private _mintCount;
    uint256 private startFrom = 1;
    uint256 private startTime;
    uint256 private tokenSum;
    mapping(uint256 => uint256) private tokenMatrix;

    mapping(address => mapping(uint => bool)) private is_minted;
    mapping(uint => bytes32) private merkle_root;
    mapping(uint => uint) private white_number;
    mapping(uint => uint) private white_minted;

    event MintMeelon(address indexed owner, uint256 tokenId);

    constructor(string memory uri, uint start_time) public ERC721("Transit NFT Meelons", "Meelons") {
        initOwner(msg.sender);
        initBaseUri(uri);
        startTime = start_time;
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function queryRoot(uint whichRoot) public view returns (bytes32) {
        return merkle_root[whichRoot];
    }

    function queryMinted(uint whichList, address account) public view returns (bool) {
        return is_minted[account][whichList];
    }

    function queryListMinted(uint whichList) public view returns (uint, uint) {
        uint totalNumber = white_number[whichList];
        uint minted = white_minted[whichList];
        return (totalNumber, minted);
    }

    function queryStartMint() public view returns (bool) {
        return startTime <= block.timestamp && startTime != 0;
    }

    function queryMintAllow(address account, uint[] memory whichList) public view returns (bool[] memory result) {
        uint256 len = whichList.length;
        result = new bool[](len);
        for (uint i; i < len; i++) {
            result[i] = !is_minted[account][whichList[i]] && white_minted[whichList[i]] < white_number[whichList[i]];
        }
    }

    function setRoot(bytes32[] memory root, uint[] memory whichRoot) public onlyOwner() {
        require(root.length == whichRoot.length, "Invaild data!");
        for (uint i; i < whichRoot.length; i++) {
            merkle_root[whichRoot[i]] = root[i];
        } 
    }

    function setWhiteNumber(uint[] memory whichList, uint[] memory number) public onlyOwner() {
        require(whichList.length == number.length, "Invaild data!");
        for (uint i; i < number.length; i++) {
            white_number[whichList[i]] = number[i];
        } 
    }

    function mintMeelon(bytes32[][] memory proof, uint[] memory whichRoot) public returns (uint256 tokenId) {
        require(!msg.sender.isContract(), "Not allow contract to mint!");
        require(_mintCount <= _totalSupply, "Mint overflow!");
        require(startTime <= block.timestamp && startTime != 0, "Non start mint!");
        uint len = proof.length;
        require(len == whichRoot.length, "Invaild data!");
        for (uint i; i < len; i++) {
            if (white_minted[whichRoot[i]] >= white_number[whichRoot[i]]) {
                continue;
            }
            require(!is_minted[msg.sender][whichRoot[i]], "Already minted!");
            require(verify(merkle_root[whichRoot[i]], proof[i], msg.sender), "Non-whitelist!");
            tokenId = nextToken();
            _safeMint(msg.sender, tokenId);
            white_minted[whichRoot[i]] = white_minted[whichRoot[i]] + 1;
            is_minted[msg.sender][whichRoot[i]] = true;
            emit MintMeelon(msg.sender, tokenId);
        }
    }

    function verify(bytes32 root, bytes32[] memory proof, address account) public view returns (bool) {
        bytes32 computedHash = keccak256(abi.encodePacked(account));
        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];
            if (computedHash <= proofElement) {
                computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
            } else {
                computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
            }
        }
        return computedHash == root;
    }

    function nextToken() internal returns (uint256) {
        uint256 maxIndex = _totalSupply - _mintCount;
        uint256 random = uint256(keccak256(
            abi.encodePacked(
                block.timestamp,
                tokenSum,
                block.coinbase,
                msg.sender,
                block.difficulty,
                block.coinbase.balance,
                block.gaslimit
            )
        )) % maxIndex;
        uint256 value = 0;
        if (tokenMatrix[random] == 0) {
            value = random;
        } else {
            value = tokenMatrix[random];
        }
        if (tokenMatrix[maxIndex - 1] == 0) {
            tokenMatrix[random] = maxIndex - 1;
        } else {
            tokenMatrix[random] = tokenMatrix[maxIndex - 1];
        }
        tokenSum = tokenSum + value + startFrom;
        _mintCount = _mintCount + 1;
        return value + startFrom;
    }

}