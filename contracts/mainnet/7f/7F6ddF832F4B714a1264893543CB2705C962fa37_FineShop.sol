// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "./FineCoreInterface.sol";

interface FineNFTInterface {
    function mint(address to) external returns (uint);
    function mintBonus(address to, uint infiniteId) external returns (uint);
    function getArtistAddress() external view returns (address payable);
    function getAdditionalPayee() external view returns (address payable);
    function getAdditionalPayeePercentage() external view returns (uint256);
    function getTokenLimit() external view returns (uint256);
    function checkPool() external view returns (uint);
    function totalSupply() external view returns (uint256);
    function balanceOf(address owner) external view returns (uint256);
}

interface BasicNFTInterface {
    function ownerOf(uint256 tokenId) external view returns (address);
    function balanceOf(address owner) external view returns (uint256);
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);
}

enum SalePhase {
  Owner,
  PreSale,
  PublicSale
}

/// @custom:security-contact [email protected]
contract FineShop is AccessControl {
    using SafeMath for uint256;

    FineCoreInterface fineCore;
    mapping(uint => address) public projectOwner;
    mapping(uint => uint) public projectPremints;
    mapping(uint => uint) public projectPrice;
    mapping(uint => address) public projectCurrencyAddress;
    mapping(uint => string) public projectCurrencySymbol;
    mapping(uint => uint) public projectBulkMintCount;
    mapping(uint => bool) public projectLive;
    mapping(uint256 => bool) public contractFilterProject;
    mapping(address => mapping (uint256 => uint256)) public projectMintCounter;
    mapping(uint256 => uint256) public projectMintLimit;
    mapping(uint256 => SalePhase) public projectPhase;
    mapping(uint256 => mapping (address => uint8) ) public projectAllowList;
    mapping(uint256 => bool ) public infinitesAIWOW;
    mapping(uint256 => mapping (uint256 => address) ) public projectGateTokens;
    mapping(uint256 => uint256) public projectGateTokensCount;
    mapping(uint256 => mapping(uint256 => mapping(uint256 => bool)) ) public redeemed; // projectID, gateContractId, gateTokenId
    
    uint256[17] wowIds = [23,211,223,233,234,244,261,268,292,300,335,359,371,386,407,501,505];

    constructor(address _fineCoreAddresss) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        fineCore = FineCoreInterface(_fineCoreAddresss);
        for (uint256 i = 0; i < 17; i++) infinitesAIWOW[wowIds[i]] = true;
    }

    function stringComp(string memory str1, string memory str2) pure internal returns (bool) {
        return keccak256(abi.encodePacked(str1)) == keccak256(abi.encodePacked(str2));
    }

    // Admin Functions

    /**
     * @dev set the owner of a project
     * @param _projectId to set owner of
     * @param newOwner to set as owner
     */
    function setOwner(uint _projectId, address newOwner) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(projectOwner[_projectId] != newOwner, "can't be same owner");
        require(newOwner != address(0x0), "owner can't be zero address");
        projectOwner[_projectId] = newOwner;
    }

    /**
     * @dev push the project to live (locks setting and can premint)
     * @param _projectId to push live
     */
    function goLive(uint _projectId) external onlyRole(DEFAULT_ADMIN_ROLE) {
        bool ready = projectPrice[_projectId] > 0 && !stringComp(projectCurrencySymbol[_projectId], "");
        require(ready, "project not ready for live");
        projectLive[_projectId] = true;
    }
  
    /**
     * @dev set the mint limiter of a project
     * @param _projectId project to set mint limit of
     * @param _limit mint limit per address
     */
    function setProjectMintLimit(uint256 _projectId, uint8 _limit) public onlyRole(DEFAULT_ADMIN_ROLE) {
        projectMintLimit[_projectId] = _limit;
    }
  
    /**
     * @dev set the bulk mint count of a project
     * @param _projectId project to set mint limit of
     * @param _count of tokens mintable 
     */
    function setProjectBulkMintCount(uint256 _projectId, uint8 _count) public onlyRole(DEFAULT_ADMIN_ROLE) {
        projectBulkMintCount[_projectId] = _count;
    }

    /**
     * @dev set the contract mint filter
     * @param _projectId project to toggle the contract minting filter on
     */
    function toggleContractFilter(uint256 _projectId) public onlyRole(DEFAULT_ADMIN_ROLE) {
        contractFilterProject[_projectId]=!contractFilterProject[_projectId];
    }

    /**
     * @dev init the project
     * @param _projectId to set owner of
     * @param newOwner to set as owner
     * @param contractFilter switch to filter out minting via contract
     * @param _bulk amount for minitng multiple per tx
     * @param _limit mintable per address
     */
    function projectInit(
        uint _projectId,
        address newOwner,
        bool contractFilter,
        uint256 _bulk,
        uint256 _limit
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(newOwner != address(0x0), "owner can't be zero address");
        projectOwner[_projectId] = newOwner;
        contractFilterProject[_projectId] = contractFilter;
        projectBulkMintCount[_projectId] = _bulk;
        projectMintLimit[_projectId] = _limit;
    }

    // Project Owner Functions

    modifier onlyOwner(uint _projectId) {
      require(msg.sender == projectOwner[_projectId], "only owner");
      _;
    }

    modifier isLive(uint _projectId) {
      require(projectLive[_projectId], "Project not yet live");
      _;
    }

    modifier notLive(uint _projectId) {
      require(!projectLive[_projectId], "Can't call once live");
      _;
    }

    /**
     * @dev set the price of a project
     * @param _projectId to set price of
     * @param price to set project to
     */
    function setPrice(uint _projectId, uint price) external onlyOwner(_projectId) notLive(_projectId) {
        projectPrice[_projectId] = price;
    }

    /**
     * @dev set the premints of a project
     * @param _projectId to set premints of
     * @param premints to set project to
     */
    function setPremints(uint _projectId, uint premints) external onlyOwner(_projectId) notLive(_projectId) {
        projectPremints[_projectId] = premints;
    }

    /**
     * @dev set the currency to ETH
     * @param _projectId to set currency of
     */
    function setCurrencyToETH(uint _projectId) external onlyOwner(_projectId) notLive(_projectId) {
        projectCurrencySymbol[_projectId] = "ETH";
        projectCurrencyAddress[_projectId] = address(0x0);
    }

    /**
     * @dev set the currency
     * @param _projectId to set currency of
     * @param _symbol of the currency
     * @param _contract address of the currency
     */
    function setCurrency(uint _projectId, string calldata _symbol, address _contract) external onlyOwner(_projectId) notLive(_projectId) {
        require(bytes(_symbol).length > 0, "Symbol must be provided");
        if (!stringComp(_symbol, "ETH"))
            require(_contract != address(0x0), "curency address cant be zero");
        projectCurrencySymbol[_projectId] = _symbol;
        projectCurrencyAddress[_projectId] = _contract;
    }

    /**
     * @dev owner may set project up in one call
     * @param _projectId to set up
     * @param _symbol of the currency
     * @param _contract address of the currency
     * @param _price of the project
     * @param _premints number available
     */
    function fullSetup(
            uint _projectId,
            string calldata _symbol,
            address _contract,
            uint256 _price,
            uint256 _premints
        ) external onlyOwner(_projectId) notLive(_projectId) {
            require(bytes(_symbol).length > 0, "Symbol must be provided");
            if (!stringComp(_symbol, "ETH"))
                require(_contract != address(0x0), "curency address cant be zero");
            projectCurrencySymbol[_projectId] = _symbol;
            projectCurrencyAddress[_projectId] = _contract;
            projectPrice[_projectId] = _price;
            projectPremints[_projectId] = _premints;
    }

    /**
     * @dev add an address to the allowlist
     * @param _projectId to set allowlist of
     * @param addresses to set allowlist counts for
     * @param numAllowedToMint number of mints to allow addresses
     */
    function setAllowList(uint _projectId, address[] calldata addresses, uint8 numAllowedToMint) external onlyOwner(_projectId) {
        for (uint256 i = 0; i < addresses.length; i++) {
            projectAllowList[_projectId][addresses[i]] = numAllowedToMint;
        }
    }

    /**
     * @dev set an NFT as a mint gating token
     * @param _projectId to set token for
     * @param addresses of token contracts
     */
    function setGateTokens(uint _projectId, address[] calldata addresses) external onlyOwner(_projectId) {
        projectGateTokensCount[_projectId] = addresses.length;
        for (uint256 i = 0; i < addresses.length; i++) {
            projectGateTokens[_projectId][i] = addresses[i];
        }
    }
    
    /**
     * @dev set mint phase of a project
     * @param _projectId to set phase of
     */
    function setPhase(uint _projectId, SalePhase phase) external onlyOwner(_projectId) isLive(_projectId) {
        projectPhase[_projectId] = phase;
    }

    // Sale Functions

    /**
     * @dev handle payment for a purchase
     * @param _projectId to handle payment for
     * @param count to purchase
     */
    function handlePayment(uint _projectId, uint count) internal {
        uint price = projectPrice[_projectId].mul(count);
        if (!stringComp(projectCurrencySymbol[_projectId], "ETH")){
            require(msg.value==0, "this project accepts a different currency and cannot accept ETH");
            require(IERC20(projectCurrencyAddress[_projectId]).allowance(msg.sender, address(this)) >= price, "Insufficient Funds Approved for TX");
            require(IERC20(projectCurrencyAddress[_projectId]).balanceOf(msg.sender) >= price, "Insufficient balance.");
            _splitFundsERC20(_projectId, count);
        } else {
            require(msg.value >= price, "Must send minimum value to mint!");
            _splitFundsETH(_projectId, count);
        }
    }

    /**
     * @dev split funds of payment made with ETH
     * @param _projectId to purchase
     * @param count number of tokens to purchase
     */
    function _splitFundsETH(uint256 _projectId, uint count) internal {
        if (msg.value > 0) {
            uint256 pricePerTokenInWei = projectPrice[_projectId];
            uint salePrice = pricePerTokenInWei.mul(count);
            uint256 refund = msg.value.sub(salePrice);
            if (refund > 0) {
                payable(msg.sender).transfer(refund);
            }
            uint256 platformAmount = salePrice.mul(fineCore.platformPercentage()).div(10000);
            if (platformAmount > 0) {
                fineCore.FINE_TREASURY().transfer(platformAmount);
            }
            FineNFTInterface nftContract = FineNFTInterface(fineCore.getProjectAddress(_projectId));
            uint256 additionalPayeeAmount = salePrice.mul(nftContract.getAdditionalPayeePercentage()).div(10000);
            if (additionalPayeeAmount > 0) {
                nftContract.getAdditionalPayee().transfer(additionalPayeeAmount);
            }
            uint256 creatorFunds = salePrice.sub(platformAmount).sub(additionalPayeeAmount);
            if (creatorFunds > 0) {
                nftContract.getArtistAddress().transfer(creatorFunds);
            }
        }
    }

    /**
     * @dev split funds of payment made with ERC20 tokens
     * @param _projectId to purchase
     * @param count number of tokens to purchase
     */
    function _splitFundsERC20(uint256 _projectId, uint count) internal {
        uint256 pricePerTokenInWei = projectPrice[_projectId];
        uint salePrice = pricePerTokenInWei.mul(count);
        uint256 platformAmount = salePrice.mul(fineCore.platformPercentage()).div(10000);
        if (platformAmount > 0) {
            IERC20(projectCurrencyAddress[_projectId]).transferFrom(msg.sender, fineCore.FINE_TREASURY(), platformAmount);
        }
        FineNFTInterface nftContract = FineNFTInterface(fineCore.getProjectAddress(_projectId));
        nftContract.getArtistAddress();
        uint256 additionalPayeeAmount = salePrice.mul(nftContract.getAdditionalPayeePercentage()).div(10000);
        if (additionalPayeeAmount > 0) {
            IERC20(projectCurrencyAddress[_projectId]).transferFrom(msg.sender, nftContract.getAdditionalPayee(), additionalPayeeAmount);
        }
        uint256 creatorFunds = salePrice.sub(platformAmount).sub(additionalPayeeAmount);
        if (creatorFunds > 0) {
            IERC20(projectCurrencyAddress[_projectId]).transferFrom(msg.sender, nftContract.getArtistAddress(), creatorFunds);
        }
    }

    // Minting Functions

    /**
     * @dev purchase tokens of a project and send to a specific address6
     * @param _projectId to purchase
     * @param to address to send token to
     * @param count number of tokens to purchase
     */
    function purchaseTo(uint _projectId, address to, uint count) internal isLive(_projectId) returns (string memory) {
        if (contractFilterProject[_projectId]) require(msg.sender == tx.origin, "No Contract Buys");
        // instantiate an interface with the projects NFT contract
        FineNFTInterface nftContract = FineNFTInterface(fineCore.getProjectAddress(_projectId));
        require(nftContract.checkPool() > 0, "Sold out");
        require(nftContract.checkPool() >= count, "Count excedes available");

        // Owner phase conditions
        if (projectPhase[_projectId] == SalePhase.Owner) {
            require(msg.sender == projectOwner[_projectId], "Only owner can mint now");
            require(count <= projectPremints[_projectId], "Excededs max premints");
            projectPremints[_projectId] -= count;
        } else {
            if (projectMintLimit[_projectId] > 0) {
                require(projectMintCounter[msg.sender][_projectId] < projectMintLimit[_projectId], "Reached minting limit");
                projectMintCounter[msg.sender][_projectId] += count;
            }
            // Presale phase conditions
            if (projectPhase[_projectId] == SalePhase.PreSale) {
                require(count <= projectAllowList[_projectId][msg.sender], "Exceeds allowlisted count");
                projectAllowList[_projectId][msg.sender] -= uint8(count);
            } else if (projectPhase[_projectId] == SalePhase.PublicSale) {
                if (projectBulkMintCount[_projectId] > 0)
                    require(count <= projectBulkMintCount[_projectId], "Count excedes bulk mint limit");
            }
            handlePayment(_projectId, count);
        }
        string memory idList;
        // mint number of tokens specified by count
        for (uint i = 0; i < count; i++) {
            uint tokenID = nftContract.mint(to);
            if (i == 0) idList = string(abi.encodePacked(tokenID));
            else idList = string(abi.encodePacked(idList, ",", tokenID));
        }

        return idList; // returns a list of ids of all tokens minted
    }

    /**
     * @dev purchase tokens of a project and send to a specific address (only holders of listed NFTs)
     * @param _projectId to purchase
     * @param to address to send token to
     * @param contractId of contract to lookup gate pass in the mapping
     * @param redeemId id of token to redeem gate pass for
     */
    function mintGated(uint _projectId, address to, uint8 contractId, uint256 redeemId) public payable isLive(_projectId) returns (string memory) {
        if (contractFilterProject[_projectId]) require(msg.sender == tx.origin, "No Contract Buys");
        // instantiate an interface with the projects NFT contract
        FineNFTInterface nftContract = FineNFTInterface(fineCore.getProjectAddress(_projectId));
        
        // Presale phase conditions
        require(projectPhase[_projectId] != SalePhase.Owner, "Must redeem after owner mint");
        BasicNFTInterface allowToken = BasicNFTInterface(projectGateTokens[_projectId][contractId]);
        require(nftContract.checkPool() > 0, "Sold out");
        require(
            allowToken.ownerOf(redeemId) == msg.sender || allowToken.ownerOf(redeemId) == to,
            "Only token owner can redeem pass");
        require(!redeemed[_projectId][contractId][redeemId], "already redeemed for ID");
        redeemed[_projectId][contractId][redeemId] = true;
        uint tokenId = nftContract.mint(to);
        // free bonus mints for coresponding Infinites AI tokens owned
        if (contractId == 0) nftContract.mintBonus(to, redeemId);
        // free mint for Infinites AI WOWs
        if (contractId != 0 || !infinitesAIWOW[redeemId]) handlePayment(_projectId, 1);
        else if (msg.value > 0) payable(msg.sender).transfer(msg.value);

        return string(abi.encodePacked(tokenId)); // returns a list of ids of all tokens minted
    }

    /**
     * @dev purchase tokens of a project
     * @param _projectId to purchase
     * @param count number of tokens to purchase
     */
    function buy(uint _projectId, uint count) external payable returns (string memory) {
        return purchaseTo(_projectId, msg.sender, count);
    }

    /**
     * @dev purchase tokens of a project for another address
     * @param _projectId to purchase
     * @param to recipients address
     * @param count number of tokens to purchase
     */
    function buyFor(uint _projectId, address to, uint count) external payable returns (string memory) {
        return purchaseTo(_projectId, to, count);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.2;

interface FineCoreInterface {
    function getProjectAddress(uint id) external view returns (address);
    function getRandomness(uint256 id, uint256 seed) external view returns (uint256 randomnesss);
    function getProjectID(address project) external view returns (uint);
    function FINE_TREASURY() external returns (address payable);
    function platformPercentage() external returns (uint256);
    function platformRoyalty() external returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

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

// SPDX-License-Identifier: MIT
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