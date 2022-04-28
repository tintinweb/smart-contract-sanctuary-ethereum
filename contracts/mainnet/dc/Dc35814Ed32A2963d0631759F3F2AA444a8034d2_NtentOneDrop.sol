// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

pragma solidity ^0.8.9;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }
}


pragma solidity ^0.8.9;
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}


// File: @openzeppelin/contracts/utils/Strings.sol

pragma solidity ^0.8.9;

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
    constructor () {
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

pragma solidity ^0.8.9;

interface NtentArtGenesis {
    function projectTokenInfo(uint256 _projectId)
        external
        view
        returns (
            address artistAddress,
            uint256 pricePerTokenInWei,
            uint256 invocations,
            uint256 maxInvocations,
            bool active,
            address purchaseContract,
            address dataContract,
            address tokenUriContract,
            bool acceptsMintPass,
            uint256 mintPassProjectId
        );

    function tokenIdToProjectId(uint256 _tokenId)
        external
        view
        returns (uint256);

    function tokensOfOwner(address) external view returns (uint256[] memory);
}

interface NtentArt {
   function mint(address _to, uint256 _projectId, uint256 quantity, address _by) external returns(uint256);
   function burn(address ownerAddress, uint256 _tokenId) external returns(uint256);
   function getPricePerTokenInWei(uint256 _projectId) external view returns(uint256);
   function projectTokenInfo(uint256 _projectId) external view returns(address artistAddress, uint256 pricePerTokenInWei, uint256 invocations, uint256 maxInvocations, bool active, address purchaseContract, address dataContract, address tokenUriContract, address transferContract, bool acceptsMintPass, uint256 mintPassProjectId);
   function tokenIdToProjectId(uint256 _tokenId) external view returns(uint256);
   function ownerOf(uint256 _tokenId) external view returns (address);
   function tokensOfOwner(address) external view returns (uint256[] memory);
   function ntentPercentage() external view returns(uint256);
}

interface ERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address _owner) external view returns (uint256 balance);

    function transfer(address _to, uint256 _value)
        external
        returns (bool success);

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) external returns (bool success);

    function approve(address _spender, uint256 _value)
        external
        returns (bool success);

    function allowance(address _owner, address _spender)
        external
        view
        returns (uint256 remaining);
}

contract NtentOneDrop is Ownable, ReentrancyGuard {
    using SafeMath for uint256;

    address public ntentGenesisTokenContractAddress;
    address public ntentTokenContractAddress;
    address public ntentDonationHoldingAddress;
    address public ntentSustainabilityFundAddress;
    address public ntentCollectiveWalletAddress;

    uint256 sustainabilityFundPercentage = 15;
    uint256 adminExpensesPercentage = 5;

    uint256 weiToEth = 10000000000000000;

    ERC20 public ape;
    ERC20 public ash;

    mapping(uint256 => uint256) public projectApePrice;
    mapping(uint256 => uint256) public projectAshPrice;

    mapping(uint256 => bool) public isRainbowListedMinting;
    
    constructor (
        address _ntentGenesisTokenAddress,
        address _ntentTokenAddress, 
        address _ntentDonationHoldingAddress,
        address _ntentFundAddress,
        address _ntentCollectiveWalletAddress) {
            ntentGenesisTokenContractAddress = _ntentGenesisTokenAddress;
            ntentTokenContractAddress = _ntentTokenAddress;
            ntentDonationHoldingAddress = _ntentDonationHoldingAddress;
            ntentSustainabilityFundAddress = _ntentFundAddress;
            ntentCollectiveWalletAddress = _ntentCollectiveWalletAddress;
    }

    function updateApeTokenAddress(address _newAddress) public onlyOwner {
        ape = ERC20(_newAddress);
    }

    function updateAshTokenAddress(address _newAddress) public onlyOwner {
        ash = ERC20(_newAddress);
    }

    function updateDonationHoldingAddress(address _newAddress) public onlyOwner {
        ntentDonationHoldingAddress = _newAddress;
    }

    function updateProjectTokenPrices(uint _projectId,  uint _apeTokensPerMint, uint _ashTokensPerMint) public onlyOwner{
        projectApePrice[_projectId] = _apeTokensPerMint * weiToEth;
        projectAshPrice[_projectId] = _ashTokensPerMint * weiToEth;
    }

    function getTokenPrices(uint256 _projectId) public view returns (uint256 apeCoinPrice, uint256 ashCoinPrice){
        apeCoinPrice = projectApePrice[_projectId];
        ashCoinPrice = projectAshPrice[_projectId];
    }
    
    function updateNtentTokenAddress(address _newAddress) public onlyOwner {
        ntentTokenContractAddress = _newAddress;
    } 

    function toggleRainbowListedMinting(uint256 _projectId) public onlyOwner {
        isRainbowListedMinting[_projectId] = !isRainbowListedMinting[
            _projectId
        ];
    }

    function isProjectRainbowListed(uint256 _projectId)
        public
        view
        returns (bool isRainbowlisted)
    {
        isRainbowlisted = isRainbowListedMinting[_projectId];
    }

     function getRainbowListProjectId(uint256 _projectId)
        public
        view
        returns (uint256 _rainbowListProjectId)
    {
        require(_projectId > 0, "Project Id doesn't exist");

        if (_projectId > 2) {
            NtentArt ntentContract = NtentArt(ntentTokenContractAddress);
            (, , , , , , , , , , uint256 rainbowListProjectId) = ntentContract
                .projectTokenInfo(_projectId);
            _rainbowListProjectId = rainbowListProjectId;
        } else {
            NtentArtGenesis ntentGenesisContract = NtentArtGenesis(
                ntentGenesisTokenContractAddress
            );
            (
                ,
                ,
                ,
                ,
                ,
                ,
                ,
                ,
                ,
                uint256 rainbowListProjectId
            ) = ntentGenesisContract.projectTokenInfo(_projectId);
            _rainbowListProjectId = rainbowListProjectId;
        }
    }

    function hasRainbowlistedToken(
        address _fromAdress,
        uint256 _mintingProjectId
    ) public view returns (bool hasToken) {
        hasToken = false;
        uint256[] memory tokensOfOwner;
        uint256 arrLength;

        uint256 rainbowListProjectId = getRainbowListProjectId(
            _mintingProjectId
        );

        if (rainbowListProjectId > 2) {
            NtentArt ntentContract = NtentArt(ntentTokenContractAddress);

            tokensOfOwner = ntentContract.tokensOfOwner(_fromAdress);
            arrLength = tokensOfOwner.length;

            for (uint256 i; i < arrLength; i++) {
                if (
                    ntentContract.tokenIdToProjectId(tokensOfOwner[i]) ==
                    rainbowListProjectId
                ) {
                    hasToken = true;
                    break;
                }
            }
        } else {
            NtentArtGenesis ntentGenesisContract = NtentArtGenesis(
                ntentGenesisTokenContractAddress
            );

            tokensOfOwner = ntentGenesisContract.tokensOfOwner(_fromAdress);
            arrLength = tokensOfOwner.length;

            for (uint256 i; i < arrLength; i++) {
                if (
                    ntentGenesisContract.tokenIdToProjectId(tokensOfOwner[i]) ==
                    rainbowListProjectId
                ) {
                    hasToken = true;
                    break;
                }
            }
        }
    }

    //For address info : see above <-> .jiwa
    function withdraw() public onlyOwner {

        uint256 balance = address(this).balance;
        uint256 apeBalance = ape.balanceOf(address(this));
        uint256 ashBalance = ash.balanceOf(address(this));

        if(apeBalance > 0){
            uint256 apeFundAmount = uint(apeBalance * sustainabilityFundPercentage) / 100;
            uint256 apeAdminAmount = uint(apeBalance * adminExpensesPercentage) / 100;
            ape.transfer(ntentSustainabilityFundAddress, apeFundAmount);
            ape.transfer(ntentCollectiveWalletAddress, apeAdminAmount);
            ape.transfer(ntentDonationHoldingAddress, ape.balanceOf(address(this)));
        }

        if(ashBalance > 0){
            uint256 ashFundAmount = uint(ashBalance * sustainabilityFundPercentage) / 100;
            uint256 ashAdminAmount = uint(ashBalance * adminExpensesPercentage) / 100;
            ash.transfer(ntentSustainabilityFundAddress, ashFundAmount);
            ash.transfer(ntentCollectiveWalletAddress, ashAdminAmount);
            ash.transfer(ntentDonationHoldingAddress, ash.balanceOf(address(this)));
        }

        if(balance > 0){
            uint256 fundAmount = uint(balance * sustainabilityFundPercentage) / 100;
            uint256 adminAmount = uint(balance * adminExpensesPercentage) / 100;
            payable(ntentSustainabilityFundAddress).transfer(fundAmount);
            payable(ntentCollectiveWalletAddress).transfer(adminAmount);
            payable(ntentDonationHoldingAddress).transfer(balance - fundAmount - adminAmount);
        }
    }
    
    function teamMint(uint256 _projectId, uint256 _tokenQuantity) public onlyOwner {
        require(_tokenQuantity > 0, "Token quantity must greater than zero");
        
        NtentArt ntentContract = NtentArt(ntentTokenContractAddress);
        
        (uint256 tokenId) = ntentContract.mint(msg.sender, _projectId, _tokenQuantity, msg.sender);
        require(tokenId > 0, "Mint failed");
    }

    function purchase(
        address _purchasedForAddress, 
        uint256 _projectId, 
        uint256 _numberOfTokens) public nonReentrant payable {

        if (isProjectRainbowListed(_projectId) == true) {
            require(
                hasRainbowlistedToken(msg.sender, _projectId) == true,
                "Not eligle for presale"
            );
        }
               
        NtentArt ntentContract = NtentArt(ntentTokenContractAddress);
    
        uint256 tokenPrice = ntentContract.getPricePerTokenInWei(_projectId);
        require(tokenPrice.mul(_numberOfTokens) <= msg.value, "Ether value sent is not correct");

        (uint256 tokenId) = ntentContract.mint(_purchasedForAddress,  _projectId, _numberOfTokens, msg.sender);
        require(tokenId > 0, "Mint failed");
    }

    function purchaseWithApe(
        address _purchasedForAddress,
        uint256 _projectId,
        uint256 _numberOfTokens
    ) public payable nonReentrant {
        require(projectApePrice[_projectId] > 0, "Ape Price Not Set");

        if (isProjectRainbowListed(_projectId) == true) {
            require(
                hasRainbowlistedToken(msg.sender, _projectId) == true,
                "Not eligle for presale"
            );
        }

        NtentArt ntentContract = NtentArt(ntentTokenContractAddress);

        uint256 cost = projectApePrice[_projectId].mul(_numberOfTokens);
        require(
            ape.allowance(msg.sender, address(this)) >= cost,
            "APE Allowance Not Enough"
        );

        require(
            ape.balanceOf(msg.sender) >= cost,
            "Not enough APE sent"
        );
        ape.transferFrom(msg.sender, address(this), cost);

        uint256 tokenId = ntentContract.mint(
            _purchasedForAddress,
            _projectId,
            _numberOfTokens,
            msg.sender
        );
        require(tokenId > 0, "Mint failed");
    }

    function purchaseWithAsh(
        address _purchasedForAddress,
        uint256 _projectId,
        uint256 _numberOfTokens
    ) public payable nonReentrant {
        require(projectAshPrice[_projectId] > 0, "Ash Price Not Set");

        if (isProjectRainbowListed(_projectId) == true) {
            require(
                hasRainbowlistedToken(msg.sender, _projectId) == true,
                "Not eligle for presale"
            );
        }

        NtentArt ntentContract = NtentArt(ntentTokenContractAddress);

        uint256 cost = projectAshPrice[_projectId].mul(_numberOfTokens);
        
        require(
            ash.allowance(msg.sender, address(this)) >= cost,
            "ASH Allowance not set"
        );

        require(
            ash.balanceOf(msg.sender) >= cost,
            "Not enough ASH sent"
        );
        
        ash.transferFrom(msg.sender, address(this), cost);

        uint256 tokenId = ntentContract.mint(
            _purchasedForAddress,
            _projectId,
            _numberOfTokens,
            msg.sender
        );
        require(tokenId > 0, "Mint failed");
    }
}