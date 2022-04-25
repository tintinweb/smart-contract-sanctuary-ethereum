pragma solidity ^0.5.0;

import './SafeMath.sol';
import './IGenArt721CoreV2.sol';

contract GenArt721Minter_DoodleLabs_Whitelist {
    using SafeMath for uint256;

    event AddMinterWhitelist(address minterAddress);
    event RemoveMinterWhitelist(address minterAddress);
    event SetMerkleRoot(uint256 indexed projectId, bytes32 indexed merkleRoot);

    IGenArt721CoreV2 genArtCoreContract;
    mapping(address => bool) public minterWhitelist;
    mapping(uint256 => mapping(address => uint256)) public whitelist;
    mapping(uint256 => bytes32) private _merkleRoot;

    modifier onlyWhitelisted() {
        require(genArtCoreContract.isWhitelisted(msg.sender), 'can only be set by admin');
        _;
    }

    modifier onlyMintWhitelisted() {
        require(minterWhitelist[msg.sender], 'only callable by minter');
        _;
    }

    constructor(address _genArtCore, address _minterAddress) public {
        genArtCoreContract = IGenArt721CoreV2(_genArtCore);
        minterWhitelist[_minterAddress] = true;
    }

    function getMerkleRoot(uint256 projectId) external view returns (bytes32 merkleRoot) {
        return _merkleRoot[projectId];
    }

    function setMerkleRoot(uint256 projectId, bytes32 merkleRoot) public onlyWhitelisted {
        _merkleRoot[projectId] = merkleRoot;
        emit SetMerkleRoot(projectId, merkleRoot);
    }

    function addMinterWhitelist(address _minterAddress) public onlyWhitelisted {
        minterWhitelist[_minterAddress] = true;
        emit AddMinterWhitelist(_minterAddress);
    }

    function removeMinterWhitelist(address _minterAddress) public onlyWhitelisted {
        minterWhitelist[_minterAddress] = false;
        emit RemoveMinterWhitelist(_minterAddress);
    }

    function getWhitelisted(uint256 projectId, address user)
        external
        view
        returns (uint256 amount)
    {
        return whitelist[projectId][user];
    }

    function increaseAmount(
        uint256 projectId,
        address to,
        uint256 quantity
    ) public onlyMintWhitelisted {
        whitelist[projectId][to] = whitelist[projectId][to].add(quantity);
    }
}