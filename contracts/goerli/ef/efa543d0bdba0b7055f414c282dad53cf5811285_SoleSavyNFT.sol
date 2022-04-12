// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import {ERC721} from "./ERC721.sol";
import {SafeTransferLib} from "./SafeTransferLib.sol";
import {Ownable} from "./Ownable.sol";
import {Strings} from "./Strings.sol";
import {MerkleProof} from "./MerkleProof.sol";
import {AccessControl} from "./AccessControl.sol";

/// @title SoleSavyNFT Contract
/// @author Julian <[email protected]>

//                    *%%%%%%     %%%%%
//           @@@@@@@@@@@@@@@@@  @@@@@@@@@@@@@ @
//      %@@@@(      /@@@@@@@@  @@(     @@@@(%@@((((@@@@@@@@@@@@@@@/
//    @@@@@@@   @@&@@,    #@@ /@. /@@  @@@/@.  %@@@@&@@@@@,,@@@,#@@@@@@@
//   @@@@@&&&@@  @@@  @@@  @/ @@  . [email protected]@&(@@@  /@@@/   / @@  @@  /@/ (@@@@@
//  /@@@      /@/ ,@  %@, /@ @@@, ,(((/@@@@@%  @@  @@@  @@  @@  @@  @@@  @@
//   @@   /@@&@@/  @@&  @@@  @@@@@@@/@      @   @  @@   @@ @@  @@ /@@@   @@
//    @@(         @@@@@@@@@   @@& /@@@  /@@@@  [email protected]@@@@@  @@    @@(   [email protected]@ @@/
//      ,@@@@@@@@@@@@@@@@@@(,((@,@@@@@@@,    (@@@@@@@@@@@@@@@@@@@@@/  %@@
//           [email protected]@@@@@@@@@@@@@@@/@@@@@.....           [email protected]@@@@@@@@@@@@@@.

contract SoleSavyNFT is ERC721, AccessControl {
    using Strings for uint256;

    uint256 public totalSupply;
    uint256 public immutable maxSupply = 1023;
    uint256 public immutable reservedAmount = 123;
    uint256 public immutable price = 0.18 ether;

    // start time for each tier
    uint256 public publicSaleStartTime = 1650312000; // Mon Apr 18 2022 20:00:00 GMT+0000
    uint256 public tierTwoAllowListStartTime = 1650225600; // Sun Apr 17 2022 20:00:00 GMT+0000
    uint256 public tierOneAllowListStartTime = 1650218400; // Sun Apr 17 2022 18:00:00 GMT+0000

    // ADMIN_ROLE is the only one that can withdraw
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    // MINT_ADMIN_ROLE can help to trigger any mint functionallity
    bytes32 public constant MINT_ADMIN_ROLE = keccak256("MINT_ADMIN_ROLE");
    bytes32 public merkleRootTierOne;
    bytes32 public merkleRootTierTwo;

    string public baseURI;

    address public vault = 0xB0a4A006fC00cF714BADDc77BA7eca081426c0dA;
    address public soleSavyTeamWallet;

    mapping(address => uint256) public amountMintedPublic;
    mapping(address => uint256) public amountMintedPresale;

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _baseURI,
        bytes32 _merkleRoot,
        bytes32 _merkleRootTwo,
        address _soleSavyTeamWallet,
        address[] memory minterRoles
    ) ERC721(_name, _symbol) {
        baseURI = _baseURI;
        merkleRootTierOne = _merkleRoot; // Update root
        merkleRootTierTwo = _merkleRootTwo;
        soleSavyTeamWallet = _soleSavyTeamWallet;

        // setup access control
        _setupRole(MINT_ADMIN_ROLE, msg.sender);

        // grant access to sole savy team
        _setupRole(MINT_ADMIN_ROLE, _soleSavyTeamWallet);
        _setupRole(DEFAULT_ADMIN_ROLE, _soleSavyTeamWallet);
        _setupRole(ADMIN_ROLE, _soleSavyTeamWallet);

        // set up mint role for LC team to help
        uint256 minterRolesLength = minterRoles.length;
        for (uint256 i = 0; i < minterRolesLength; ) {
            _setupRole(MINT_ADMIN_ROLE, minterRoles[i]);
            unchecked {
                i++;
            }
        }
    }

    /*///////////////////////////////////////////////////////////////
                               MINT FUNCTION
    //////////////////////////////////////////////////////////////*/

    /// @notice Mint NFT function.
    /// @param amount is the amount of NFT that the user will mint
    function publicSalesMint(uint256 amount) external payable {
        require(
            isSaleActive(publicSaleStartTime),
            "SSNFT: Public sale has not started yet."
        );
        require(
            totalSupply + amount <= maxSupply - reservedAmount,
            "SSNFT: Sold out"
        );
        require(amount <= 3, "SSNFT: You can only mint 3 in each transaction.");
        require(msg.value == price * amount, "SSNFT: Wrong ether value");
        require(
            amountMintedPublic[msg.sender] + amount <= 3,
            "SSNFT: You can only mint 3 in total on Public Sale."
        );

        _mintMultiple(amount);
        unchecked {
            amountMintedPublic[msg.sender] += amount;
        }
    }

    function allowListMintTierOne(uint256 amount, bytes32[] calldata proof)
        external
        payable
    {
        require(
            isSaleActive(tierOneAllowListStartTime),
            "SSNFT: Allowlist Tier One sale has not started yet."
        );
        require(msg.value == price * amount, "SSNFT: Wrong ether value.");
        require(amount <= 3, "SSNFT: You can only mint 3 in each transaction.");
        require(
            totalSupply + amount <= maxSupply - reservedAmount,
            "SSNFT: Sold out"
        );
        require(
            amountMintedPresale[msg.sender] + amount <= 3,
            "SSNFT: You can only mint 3 in total on Pre Sale."
        );

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        bool isValidLeaf = MerkleProof.verify(proof, merkleRootTierOne, leaf);
        require(isValidLeaf, "SSNFT: You are not on the allow list.");

        _mintMultiple(amount);
        unchecked {
            amountMintedPresale[msg.sender] += amount;
        }
    }

    function allowListMintTierTwo(uint256 amount, bytes32[] calldata proof)
        external
        payable
    {
        require(
            isSaleActive(tierTwoAllowListStartTime),
            "SSNFT: Allowlist Tier Two sale has not started yet."
        );
        require(msg.value == price * amount, "SSNFT: Wrong ether value.");
        require(amount <= 3, "SSNFT: You can only mint 3 in each transaction.");
        require(
            totalSupply + amount <= maxSupply - reservedAmount,
            "SSNFT: Sold out"
        );
        require(
            amountMintedPresale[msg.sender] + amount <= 3,
            "SSNFT: You can only mint 3 in total on Pre Sale."
        );

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        bool isValidLeaf = MerkleProof.verify(proof, merkleRootTierTwo, leaf);
        require(isValidLeaf, "SSNFT: You are not on the allow list.");

        _mintMultiple(amount);
        unchecked {
            amountMintedPresale[msg.sender] += amount;
        }
    }

    function _mintMultiple(uint256 amount) internal {
        for (uint256 index = 0; index < amount; ) {
            unchecked {
                _mint(msg.sender, totalSupply++);
                index++;
            }
        }
    }

    /// @notice detecting has sale started from internal variables.
    /// @param _time is the uint256 unix timestamp from internal variables.
    function isSaleActive(uint256 _time) public view returns (bool) {
        return _time > 0 && block.timestamp >= _time;
    }

    /*///////////////////////////////////////////////////////////////
                            ADMIN FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    //! need to make sure if we need this, might just remove it if we want to make it immutable

    /// @notice changing merkleRoot for tier 1 minting.
    /// @param _merkleRoot is the new merkle root
    function setMerkleRootTierOne(bytes32 _merkleRoot)
        external
        onlyRole(MINT_ADMIN_ROLE)
    {
        merkleRootTierOne = _merkleRoot;
    }

    /// @notice changing merkleRoot for tier 2 minting.
    /// @param _merkleRoot is the new merkle root
    function setMerkleRootTierTwo(bytes32 _merkleRoot)
        external
        onlyRole(MINT_ADMIN_ROLE)
    {
        merkleRootTierTwo = _merkleRoot;
    }

    /// @notice admin can mint before the sale started.
    /// @param to is the address that the NFT will be minted.
    /// @param amount is the amount that we want to mint.
    function reserve(address to, uint256 amount)
        external
        onlyRole(MINT_ADMIN_ROLE)
    {
        require(totalSupply + amount <= maxSupply, "SSNFT: Sold out");

        for (uint256 index = 0; index < amount; ) {
            unchecked {
                _mint(to, totalSupply++);
                index++;

                amountMintedPresale[msg.sender]++;
            }
        }
    }

    /// @notice changing publicSaleStartTime.
    /// @param _publicSaleStartTime is the new date for the public mint start time.
    function setPublicSaleStartTime(uint256 _publicSaleStartTime)
        external
        onlyRole(MINT_ADMIN_ROLE)
    {
        publicSaleStartTime = _publicSaleStartTime;
    }

    /// @notice changing tierTwoAllowListStartTime.
    /// @param _tierTwoAllowListStartTime is the new date for the tier two mint start time.
    function setTierTwoAllowListStartTime(uint256 _tierTwoAllowListStartTime)
        external
        onlyRole(MINT_ADMIN_ROLE)
    {
        tierTwoAllowListStartTime = _tierTwoAllowListStartTime;
    }

    /// @notice changing tierOneAllowListStartTime.
    /// @param _tierOneAllowListStartTime is the new date for the tier one mint start time.
    function setTierOneAllowListStartTime(uint256 _tierOneAllowListStartTime)
        external
        onlyRole(MINT_ADMIN_ROLE)
    {
        tierOneAllowListStartTime = _tierOneAllowListStartTime;
    }

    /*///////////////////////////////////////////////////////////////
                            ETH WITHDRAWAL
    //////////////////////////////////////////////////////////////*/

    /// @notice Withdraw all ETH from the contract to the vault address. only ADMIN_ROLE can do this.
    function withdraw() external onlyRole(ADMIN_ROLE) {
        require(address(this).balance > 0, "Balance is empty");
        SafeTransferLib.safeTransferETH(vault, address(this).balance);
    }

    /// @notice Change the vault address. only ADMIN_ROLE can do this.
    /// @param _vault is the new vault address
    function setVault(address _vault) external onlyRole(ADMIN_ROLE) {
        vault = _vault;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(ownerOf(tokenId) != address(0), "SSNFT: Token does not exist");

        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, tokenId.toString(), ".json"))
                : "";
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}