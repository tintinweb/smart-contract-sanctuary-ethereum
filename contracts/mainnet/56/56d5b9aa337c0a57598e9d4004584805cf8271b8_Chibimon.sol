// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import './ERC721A.sol';
import './Ownable.sol';
import './ECDSA.sol';

error IncorrectSignature();
error SoldOut();
error MaxMintTokensExceeded();
error AddressCantBeBurner();
error CantWithdrawFunds();
error StakingNotActive();
error SenderNotOwner();
error AlreadyStaked();
error TokenIsStaked();
error NotStaked();
error NeedMoreStakingTime();

contract Chibimon is ERC721A, Ownable {
    using ECDSA for bytes32;

    address private _signerAddress;
    address private _authorWallet;

    string public baseURI;
    uint256 public maxSupply;
    bool public stakingStatus;
    uint256 public revealTime;

    mapping(uint256 => uint256) public tokenStaked;
    mapping(uint256 => bool) public tokenRevealed;

    constructor( uint256 newMaxSupply, address newSignerAddress, string memory newBaseURI, bool newStakingStatus, uint256 newRevealTime ) ERC721A("Chibimon", "CHBMN") {
        maxSupply = newMaxSupply;
        baseURI = newBaseURI;
        _signerAddress = newSignerAddress;
        stakingStatus = newStakingStatus;
        revealTime = newRevealTime;
    }

    // public functions

    /**
     * @dev Important: You will need a valid signature to mint. The signature will only be generated on the official website.
     */
    function mint(bytes calldata signature, uint256 quantity, uint256 maxMintable, bool stakeTokens) external payable {
        if( !_verifySig(msg.sender, msg.value, maxMintable, signature) ) revert IncorrectSignature();
        if( totalSupply() + quantity > maxSupply ) revert SoldOut();
        if( _numberMinted(msg.sender) + quantity > maxMintable ) revert MaxMintTokensExceeded();

        uint256 tokenIdStart = _nextTokenId();

        _mint(msg.sender, quantity);

        if( stakeTokens ) {
            uint256 tokenIdEnd = _nextTokenId();

            while( tokenIdStart < tokenIdEnd ) {
                tokenStaked[tokenIdStart] = block.timestamp;
                tokenIdStart++;
            }
        }
    }

    /**
     * @dev Check how many tokens the given address minted
     */
    function numberMinted(address minter) external view returns(uint256) {
        return _numberMinted(minter);
    }

    /**
     * @dev Stake the given token
     */
    function stake(uint256 tokenId) public {
        if( !stakingStatus ) revert StakingNotActive();
        if( msg.sender != ownerOf(tokenId) && msg.sender != owner() ) revert SenderNotOwner();
        if( tokenStaked[tokenId] != 0 ) revert AlreadyStaked();

        tokenStaked[tokenId] = block.timestamp;
    }

    /**
     * @dev Unstake the given token
     */
    function unstake(uint256 tokenId) public {
        if( msg.sender != ownerOf(tokenId) && msg.sender != owner() ) revert SenderNotOwner();
        if( tokenStaked[tokenId] == 0 ) revert NotStaked();

        tokenStaked[tokenId] = 0;
    }

    /**
     * @dev Batch stake/unstake the given tokens
     */
    function batchStakeStatus(uint256[] memory tokenIds, bool status) external {
        for (uint256 i; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            if (status) {
                stake(tokenId);
            } else {
                unstake(tokenId);
            }
        }
    }

    /**
     * @dev Reveal given token if staked long enough (s. reveal time)
     */
    function reveal(uint256 tokenId) public {
        if( msg.sender != ownerOf(tokenId) && msg.sender != owner() ) revert SenderNotOwner();
        if( tokenStaked[tokenId] == 0 ) revert NotStaked();
        if( block.timestamp - tokenStaked[tokenId] < revealTime ) revert NeedMoreStakingTime();

        tokenRevealed[tokenId] = true;
        tokenStaked[tokenId] = 0;
    }

    /**
     * @dev Returns the tokenIds of the given address
     */ 
    function tokensOf(address owner) external view returns (uint256[] memory) {
        unchecked {
            uint256[] memory tokenIds = new uint256[](balanceOf(owner));
            uint256 tokenIdsIdx;

            for (uint256 i; i < totalSupply(); i++) {

                TokenOwnership memory ownership = _ownershipOf(i);

                if (ownership.burned || ownership.addr == address(0)) {
                    continue;
                }

                if (ownership.addr == owner) {
                    tokenIds[tokenIdsIdx++] = i;
                }

            }

            return tokenIds;
        }
    }

    // internal functions

    function _verifySig(address sender, uint256 valueSent, uint256 maxMintable, bytes memory signature) internal view returns(bool) {
        bytes32 messageHash = keccak256(abi.encodePacked(sender, valueSent, maxMintable));
        return _signerAddress == messageHash.toEthSignedMessageHash().recover(signature);
    }

    // owner functions

    /**
     * @dev Batch aidrop tokens to given addresses (onlyOwner)
     */
    function giveaway(address[] calldata receivers, uint256[] calldata quantities ) external onlyOwner {

        uint256 totalQuantity = 0;

        for( uint256 i = 0; i < quantities.length; i++ ) {
            totalQuantity += quantities[i];
        }

        if( totalSupply() + totalQuantity > maxSupply ) revert SoldOut();

        for( uint256 i = 0; i < receivers.length; i++ ) {
            _mint(receivers[i], quantities[i]);
        }
    }

    /**
     * @dev Set the signer address to verify signatures (onlyOwner)
     */
    function setSignerAddress(address newSignerAddress) external onlyOwner {
        if( newSignerAddress == address(0) ) revert AddressCantBeBurner();
        _signerAddress = newSignerAddress;
    }

    /**
     * @dev Set base uri for token metadata (onlyOwner)
     */
    function setBaseURI(string memory newBaseURI) external onlyOwner {
        baseURI = newBaseURI;
    }

    /**
     * @dev Enable/Disable staking (onlyOwner)
     */
    function setStakingStatus(bool status) external onlyOwner {
        stakingStatus = status;
    }

    /**
     * @dev Set reveal time in seconds (onlyOwner)
     */
    function setRevealTime(uint256 time) external onlyOwner {
        revealTime = time;
    }

    /**
     * @dev Withdraw all funds (onlyOwner)
     */
    function withdrawAll() external onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        if( !success ) revert CantWithdrawFunds();
    }

    // overrides

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override(ERC721A) {
        if( tokenStaked[tokenId] != 0 ) revert TokenIsStaked();
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public override(ERC721A) {
        if( tokenStaked[tokenId] != 0 ) revert TokenIsStaked();
        super.safeTransferFrom(from, to, tokenId, _data);
    }

}