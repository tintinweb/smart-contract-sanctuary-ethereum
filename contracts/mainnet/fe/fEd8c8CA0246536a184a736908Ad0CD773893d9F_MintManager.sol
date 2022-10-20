// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.0;

import {ReentrancyGuard} from "./ReentrancyGuard.sol";
import "./AccessControl.sol";
import {MerkleTokenClaimDataManager} from "./MerkleTokenClaimDataManager.sol";
import "./IERC20.sol";
import "./ERC721.sol";

contract MintManager is AccessControl, ReentrancyGuard {
    bytes32 private constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    uint64 public constant MAX_MINTABLE_PER_TX = 4;
    uint64 public constant MAX_MINTABLE_PUBLIC = 40;
    uint64 public immutable NUM_INITIAL_MINTABLE;
    uint64 public immutable NUM_PRESALE_MINTABLE;

    uint256 public mintPricePresale;
    uint256 public mintPricePublic;

    enum MINTMODE {DEVELOPMENT, PRESALE, PUBLIC}
    MINTMODE public mintMode = MINTMODE.DEVELOPMENT;

    MerkleTokenClaimDataManager public presaleManager;

    event PresaleMerkleRootSet(bytes32 merkleRoot);

    ERC721 public token;

    /** @dev Checks if sender address has admin role
     */
    modifier onlyAdmin() {
        require(hasRole(ADMIN_ROLE, msg.sender), "Does not have admin role");
        _;
    }

    constructor(
        address[] memory admins,
        uint64 _numInitialMintable,
        uint64 _numPresaleMintable,
        uint256 _presaleMintPrice,
        uint256 _publicMintPrice
    ) public {
        for (uint256 i = 0; i < admins.length; ++i) {
            _setupRole(ADMIN_ROLE, admins[i]);
        }

        NUM_INITIAL_MINTABLE = _numInitialMintable;
        NUM_PRESALE_MINTABLE = _numPresaleMintable;
        mintPricePresale = _presaleMintPrice;
        mintPricePublic = _publicMintPrice;
    }

    function setToken(ERC721 _token) public onlyAdmin {
        token = _token;
    }

    function checkCanMintPublic(
        address minterAddress,
        uint256 value,
        uint256 amount
    ) external nonReentrant {
        require(amount > 0, "Amount must be greater than 0");
        require(mintMode == MINTMODE.PUBLIC, "Public minting not enabled");
        require(value >= mintPricePublic * amount, "Insufficient funds");
        require(amount <= MAX_MINTABLE_PER_TX, "Amount exceeds allowance per tx");
        require(
            token.balanceOf(minterAddress) + amount <= MAX_MINTABLE_PUBLIC,
            "Amount requested will exceed address allowance"
        );
    }

    function checkCanMintPresale(
        address minterAddress,
        uint256 value,
        uint256 index,
        uint256 maxAmount,
        bytes32[] calldata merkleProof,
        uint256 amountDesired
    ) external nonReentrant {
        require(amountDesired > 0, "Amount must be greater than 0");
        require(
            token.totalSupply() + amountDesired <= NUM_INITIAL_MINTABLE + NUM_PRESALE_MINTABLE,
            "Amount will exceed maximum number of presale NFTs"
        );
        require(mintMode == MINTMODE.PRESALE, "Presale minting not enabled");
        require(address(presaleManager) != address(0), "Merkle root not set");
        require(value >= mintPricePresale * amountDesired, "Insufficient funds");
        require(!presaleManager.hasClaimed(index), "Address already minted");

        // Verify the merkle proof.
        presaleManager.verifyAndSetClaimed(index, minterAddress, maxAmount, merkleProof);
    }

    function checkCanMintInitial(uint256 amountToMint) public nonReentrant returns (uint256) {
        require(
            token.totalSupply() + amountToMint <= NUM_INITIAL_MINTABLE,
            "Amount will exceed maximum number of initial NFTs"
        );
    }

    function setPresaleMintingMerkleRoot(bytes32 merkleRoot) public onlyAdmin {
        if (address(presaleManager) != address(0)) {
            delete presaleManager;
        }

        presaleManager = new MerkleTokenClaimDataManager(merkleRoot);
        emit PresaleMerkleRootSet(merkleRoot);
    }

    function rescueTokens(address tokenAddress) public onlyAdmin {
        uint256 balance = IERC20(tokenAddress).balanceOf(address(this));
        require(IERC20(tokenAddress).transfer(msg.sender, balance), "rescueTokens: Transfer failed.");
    }

    function setPublicSalePrice(uint256 price) public onlyAdmin {
        mintPricePublic = price;
    }

    function setPresalePrice(uint256 price) public onlyAdmin {
        mintPricePresale = price;
    }

    function setMintingMode(MINTMODE mode) public onlyAdmin {
        mintMode = mode;
    }

    function withdrawFunds(address payable _to) public onlyAdmin {
        (bool success, ) = _to.call{value: address(this).balance}("");
        require(success, "Failed to transfer the funds, aborting.");
    }
}