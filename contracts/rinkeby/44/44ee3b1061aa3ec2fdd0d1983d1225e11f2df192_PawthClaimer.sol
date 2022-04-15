/**
 *Submitted for verification at Etherscan.io on 2022-04-15
*/

// SPDX-License-Identifier: None
pragma solidity ^0.8.13;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

interface IERC721 {
    function balanceOf(address owner) external view returns (uint256 balance);
    function tokenOfOwnerByIndex(address _owner, uint256 _index) external view returns (uint256);
}

interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
}

contract PawthClaimer is Ownable {
    IERC721 constant public nft = IERC721(0x047553bE04FDC942C2d26A1d81c6eb198Dea5A4A);
    IERC20 constant public pawth = IERC20(0x459BC05bF203cEd24E76c598B507aEAa9eD36C28);
    // mapping(address => uint256) public claims;
    uint256 public claimPerNft = 100e9;

    event Claimed(address claimer, uint256 amount);

    mapping(uint => bool) public claims;

    constructor() {}

    // function claim () public {
    //     uint256 nftBalance = nft.balanceOf(msg.sender);
    //     require(nftBalance > 0, "Not an NFT holder");
    //     uint256 entitledClaimAmount = nftBalance * claimPerNft;
    //     uint256 amountClaimed = claims[msg.sender];
    //     uint256 amountToClaim = entitledClaimAmount - amountClaimed;
    //     require(amountToClaim > 0, "No tokens to claim");
    //     claims[msg.sender] += amountToClaim;
    //     pawth.transfer(msg.sender, amountToClaim);

    //     emit Claimed(msg.sender, amountToClaim);
    // }

    function claim () public {
        uint[] memory _tokensOfOwner = getTokenIds(_msgSender());
        uint i;
        
        uint amountToClaim = 0;
        for (i=0; i<_tokensOfOwner.length; i++) {
            if (claims[i] == false) {
                claims[i] = true;
                amountToClaim += claimPerNft;
            }
        }

        require (amountToClaim > 0, "No tokens to claim");
        pawth.transfer(_msgSender(), amountToClaim);
        emit Claimed(_msgSender(), amountToClaim);
    }

    function getTokenIds(address _owner) public view returns (uint[] memory) {
        uint256 nftBalance = nft.balanceOf(_owner);
        require (nftBalance > 0, "Not an NFT holder");
        uint[] memory _tokensOfOwner = new uint[](nftBalance);
        uint i;

        for (i=0; i<nftBalance; i++) {
            _tokensOfOwner[i] = nft.tokenOfOwnerByIndex(_owner, i);
        }
        return (_tokensOfOwner);
    }
}