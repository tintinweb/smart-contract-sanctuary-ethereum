// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.11;

error NoEthBalance();

import {Ownable} from "./Ownable.sol";
import {SafeTransferLib} from "./SafeTransferLib.sol";

import {ERC1155} from "./ERC1155.sol";

/// @title CryptoCollegeCohort2
/// @author Julian <[email protected]>
contract CryptoCollegeCohort2 is ERC1155, Ownable {
    /*///////////////////////////////////////////////////////////////
                            TOKEN METADATA
    //////////////////////////////////////////////////////////////*/
    string public name;
    string public symbol;
    address public vaultAddress;

    /*///////////////////////////////////////////////////////////////
                            TOKEN DATA
    //////////////////////////////////////////////////////////////*/
    uint256 public immutable blackMaxSupply = 166;
    uint256 public immutable generalMaxSupply = 330;
    uint256 public immutable blackScholarshipTotal = 17;
    uint256 public immutable generalScholarshipTotal = 33;

    uint256 public immutable blackPrice = 0.75 ether;
    uint256 public immutable generalPrice = 0.15 ether;

    uint256 public immutable blackTokenId = 1;
    uint256 public immutable generalTokenId = 2;

    bool public hasSaleStarted = false;

    /*///////////////////////////////////////////////////////////////
                            STORAGE
    //////////////////////////////////////////////////////////////*/
    mapping(uint256 => uint256) private _totalSupply;
    mapping(uint256 => string) public tokenURI;
    mapping(address => uint256) public generalMinted;
    mapping(address => uint256) public blackMinted;

    /*///////////////////////////////////////////////////////////////
                            CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/
    constructor(
        string memory _name,
        string memory _symbol,
        address _vaultAddress,
        string memory _blackTokenUri,
        string memory _generalTokenUri
    ) {
        name = _name;
        symbol = _symbol;
        vaultAddress = _vaultAddress;
        tokenURI[generalTokenId] = _generalTokenUri;
        tokenURI[blackTokenId] = _blackTokenUri;
    }

    /// @notice totalSupply of a token ID
    /// @param id is the ID, either generalTokenId or blackTokenId
    function totalSupply(uint256 id) public view virtual returns (uint256) {
        return _totalSupply[id];
    }

    /*///////////////////////////////////////////////////////////////
                            public mint
    //////////////////////////////////////////////////////////////*/
    /// @notice function to mint the black version of the token. can only mint 1 per transaction.
    function mintBlack() external payable {
        require(hasSaleStarted, "CCC2: Sale not started yet.");
        require(
            1 + totalSupply(blackTokenId) <=
                blackMaxSupply - blackScholarshipTotal,
            "CCC2: Black membership sold out."
        );
        require(blackMinted[msg.sender] < 5, "CCC2: you can only mint 5.");
        require(msg.value == blackPrice, "CCC2: Wrong ether value.");

        _mint(msg.sender, blackTokenId, 1, "");

        unchecked {
            blackMinted[msg.sender]++;
        }
    }

    /// @notice function to mint the general version of the token. can only mint 1 per transaction.
    function mintGeneral() external payable {
        require(hasSaleStarted, "CCC2: Sale not started yet.");
        require(
            1 + totalSupply(generalTokenId) <=
                generalMaxSupply - generalScholarshipTotal,
            "CCC2: General membership sold out."
        );
        require(generalMinted[msg.sender] < 5, "CCC2: You can only mint 5.");
        require(msg.value == generalPrice, "CCC2: Wrong ether value.");

        _mint(msg.sender, generalTokenId, 1, "");

        unchecked {
            generalMinted[msg.sender]++;
        }
    }

    /*///////////////////////////////////////////////////////////////
                        ownerOnly FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice function to toggle sale state
    function startSale() external onlyOwner {
        hasSaleStarted = true;
    }

    function pauseSale() external onlyOwner {
        hasSaleStarted = false;
    }

    /// @notice function to change the tokenURI
    /// @param _newTokenURI this is the new token uri
    /// @param tokenId this is the token ID that will be set
    function setTokenURI(string memory _newTokenURI, uint256 tokenId)
        external
        onlyOwner
    {
        tokenURI[tokenId] = _newTokenURI;
    }

    /// @notice function for owner to mint (LC)
    /// @param to address to mint it to.
    function mintScholarship(address to) external onlyOwner {
        // mint black
        _mint(to, blackTokenId, blackScholarshipTotal, "");
        // mint general
        _mint(to, generalTokenId, generalScholarshipTotal, "");
    }

    /// @notice function for owner to mint the token,
    /// just in case it's needed, mintScholarship() will be used to mint all the scholarships
    /// @param to address to mint it to.
    /// @param amount the amount that the owner wants to mint.
    /// @param tokenId which token ID 1 for black 2 for general
    function ownerMint(
        address to,
        uint256 amount,
        uint256 tokenId
    ) external onlyOwner {
        require(
            tokenId == generalTokenId || tokenId == blackTokenId,
            "CCC2: Nonexistent token ID."
        );

        if (tokenId == generalTokenId) {
            require(
                amount + totalSupply(generalTokenId) <= generalMaxSupply,
                "CCC2: Amount is larger than totalSupply."
            );
            _mint(to, tokenId, amount, "");
        } else {
            require(
                amount + totalSupply(blackTokenId) <= blackMaxSupply,
                "CCC2: Amount is larger than totalSupply."
            );
            _mint(to, tokenId, amount, "");
        }
    }

    /*///////////////////////////////////////////////////////////////
                            ETH WITHDRAWAL
    //////////////////////////////////////////////////////////////*/

    /// @notice Withdraw all ETH from the contract to the vault addres.
    function withdraw() external onlyOwner {
        if (address(this).balance == 0) revert NoEthBalance();
        SafeTransferLib.safeTransferETH(vaultAddress, address(this).balance);
    }

    /// @notice changing vault address
    /// @param _vaultAddress is the new vaultAddress
    function setVault(address _vaultAddress) external onlyOwner {
        vaultAddress = _vaultAddress;
    }

    /// @notice returns the token URI
    /// @param tokenId which token ID to return 1 or 2.
    function uri(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        if (bytes(tokenURI[tokenId]).length == 0) {
            return "";
        }

        return tokenURI[tokenId];
    }

    /*///////////////////////////////////////////////////////////////
                    OVERRIDE INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/
    // override _mint to increase total supply of a token
    function _mint(
        address account,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual override {
        super._mint(account, id, amount, data);

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            _totalSupply[id] += amount;
        }
    }

    function _batchMint(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override {
        super._batchMint(to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; ++i) {
            _totalSupply[ids[i]] += amounts[i];
        }
    }

    function _burn(
        address account,
        uint256 id,
        uint256 amount
    ) internal virtual override {
        super._burn(account, id, amount);

        // Cannot underflow because a user's balance
        // will never be larger than the total supply.
        unchecked {
            _totalSupply[id] -= amount;
        }
    }

    function _batchBurn(
        address account,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual override {
        super._batchBurn(account, ids, amounts);

        for (uint256 i = 0; i < ids.length; ++i) {
            _totalSupply[ids[i]] -= amounts[i];
        }
    }
}