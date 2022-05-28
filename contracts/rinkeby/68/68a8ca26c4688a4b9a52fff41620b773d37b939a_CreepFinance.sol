/**
 *Submitted for verification at Etherscan.io on 2022-05-28
*/

// SPDX-License-Identifier: MIT

// dev address is 0xEaC458B2F78b8cb37c9471A9A0723b4Aa6b4c62D

// File @openzeppelin/contracts/token/ERC20/[email protected]

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
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

// File @openzeppelin/contracts/security/[email protected]

// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
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

// File @api3/airnode-protocol/contracts/rrp/interfaces/[email protected]

pragma solidity ^0.8.0;

interface IAuthorizationUtilsV0 {
    function checkAuthorizationStatus(
        address[] calldata authorizers,
        address airnode,
        bytes32 requestId,
        bytes32 endpointId,
        address sponsor,
        address requester
    ) external view returns (bool status);

    function checkAuthorizationStatuses(
        address[] calldata authorizers,
        address airnode,
        bytes32[] calldata requestIds,
        bytes32[] calldata endpointIds,
        address[] calldata sponsors,
        address[] calldata requesters
    ) external view returns (bool[] memory statuses);
}

// File @api3/airnode-protocol/contracts/rrp/interfaces/[email protected]

pragma solidity ^0.8.0;

interface ITemplateUtilsV0 {
    event CreatedTemplate(
        bytes32 indexed templateId,
        address airnode,
        bytes32 endpointId,
        bytes parameters
    );

    function createTemplate(
        address airnode,
        bytes32 endpointId,
        bytes calldata parameters
    ) external returns (bytes32 templateId);

    function getTemplates(bytes32[] calldata templateIds)
        external
        view
        returns (
            address[] memory airnodes,
            bytes32[] memory endpointIds,
            bytes[] memory parameters
        );

    function templates(bytes32 templateId)
        external
        view
        returns (
            address airnode,
            bytes32 endpointId,
            bytes memory parameters
        );
}

// File @api3/airnode-protocol/contracts/rrp/interfaces/[email protected]

pragma solidity ^0.8.0;

interface IWithdrawalUtilsV0 {
    event RequestedWithdrawal(
        address indexed airnode,
        address indexed sponsor,
        bytes32 indexed withdrawalRequestId,
        address sponsorWallet
    );

    event FulfilledWithdrawal(
        address indexed airnode,
        address indexed sponsor,
        bytes32 indexed withdrawalRequestId,
        address sponsorWallet,
        uint256 amount
    );

    function requestWithdrawal(address airnode, address sponsorWallet) external;

    function fulfillWithdrawal(
        bytes32 withdrawalRequestId,
        address airnode,
        address sponsor
    ) external payable;

    function sponsorToWithdrawalRequestCount(address sponsor)
        external
        view
        returns (uint256 withdrawalRequestCount);
}

// File @api3/airnode-protocol/contracts/rrp/interfaces/[email protected]

pragma solidity ^0.8.0;

interface IAirnodeRrpV0 is
    IAuthorizationUtilsV0,
    ITemplateUtilsV0,
    IWithdrawalUtilsV0
{
    event SetSponsorshipStatus(
        address indexed sponsor,
        address indexed requester,
        bool sponsorshipStatus
    );

    event MadeTemplateRequest(
        address indexed airnode,
        bytes32 indexed requestId,
        uint256 requesterRequestCount,
        uint256 chainId,
        address requester,
        bytes32 templateId,
        address sponsor,
        address sponsorWallet,
        address fulfillAddress,
        bytes4 fulfillFunctionId,
        bytes parameters
    );

    event MadeFullRequest(
        address indexed airnode,
        bytes32 indexed requestId,
        uint256 requesterRequestCount,
        uint256 chainId,
        address requester,
        bytes32 endpointId,
        address sponsor,
        address sponsorWallet,
        address fulfillAddress,
        bytes4 fulfillFunctionId,
        bytes parameters
    );

    event FulfilledRequest(
        address indexed airnode,
        bytes32 indexed requestId,
        bytes data
    );

    event FailedRequest(
        address indexed airnode,
        bytes32 indexed requestId,
        string errorMessage
    );

    function setSponsorshipStatus(address requester, bool sponsorshipStatus)
        external;

    function makeTemplateRequest(
        bytes32 templateId,
        address sponsor,
        address sponsorWallet,
        address fulfillAddress,
        bytes4 fulfillFunctionId,
        bytes calldata parameters
    ) external returns (bytes32 requestId);

    function makeFullRequest(
        address airnode,
        bytes32 endpointId,
        address sponsor,
        address sponsorWallet,
        address fulfillAddress,
        bytes4 fulfillFunctionId,
        bytes calldata parameters
    ) external returns (bytes32 requestId);

    function fulfill(
        bytes32 requestId,
        address airnode,
        address fulfillAddress,
        bytes4 fulfillFunctionId,
        bytes calldata data,
        bytes calldata signature
    ) external returns (bool callSuccess, bytes memory callData);

    function fail(
        bytes32 requestId,
        address airnode,
        address fulfillAddress,
        bytes4 fulfillFunctionId,
        string calldata errorMessage
    ) external;

    function sponsorToRequesterToSponsorshipStatus(
        address sponsor,
        address requester
    ) external view returns (bool sponsorshipStatus);

    function requesterToRequestCountPlusOne(address requester)
        external
        view
        returns (uint256 requestCountPlusOne);

    function requestIsAwaitingFulfillment(bytes32 requestId)
        external
        view
        returns (bool isAwaitingFulfillment);
}

// File @api3/airnode-protocol/contracts/rrp/requesters/[email protected]

pragma solidity ^0.8.0;

/// @title The contract to be inherited to make Airnode RRP requests
contract RrpRequesterV0 {
    IAirnodeRrpV0 public immutable airnodeRrp;

    /// @dev Reverts if the caller is not the Airnode RRP contract.
    /// Use it as a modifier for fulfill and error callback methods, but also
    /// check `requestId`.
    modifier onlyAirnodeRrp() {
        require(msg.sender == address(airnodeRrp), "Caller not Airnode RRP");
        _;
    }

    /// @dev Airnode RRP address is set at deployment and is immutable.
    /// RrpRequester is made its own sponsor by default. RrpRequester can also
    /// be sponsored by others and use these sponsorships while making
    /// requests, i.e., using this default sponsorship is optional.
    /// @param _airnodeRrp Airnode RRP contract address
    constructor(address _airnodeRrp) {
        airnodeRrp = IAirnodeRrpV0(_airnodeRrp);
        IAirnodeRrpV0(_airnodeRrp).setSponsorshipStatus(address(this), true);
    }
}

// File contracts/CreepFinance.sol

pragma solidity ^0.8.0;

interface IERC20Burnable is IERC20 {
    function burn(uint256 amount) external;
}

contract CreepFinance is ReentrancyGuard, RrpRequesterV0 {
    uint256 public fee = 4; // 4% fee for 2% burning, 2% team
    uint256 public poolSize;
    uint256 public api3Gas;
    address public owner;
    address public treasuryWallet = 0x16Ffeb2eEc52CAa102256F05EB91e095746319a6;
    address public devWallet = 0xEaC458B2F78b8cb37c9471A9A0723b4Aa6b4c62D;
    address public virtualFTMaddress =
        0x0000000000000000000000000000000000000000;

    // These can be set using setRequestParameters())
    address public airnode;
    address public sponsorWallet;
    bytes32 public endpointIdUint256;
    uint256 public sponsorBalance;

    struct Pool {
        address tokenAddress;
        uint256 tokenAmount;
        bool burning;
        bool status;
        bool[] winners;
        address[] firstPlayers;
        address[] secondPlayers;
    }

    struct Burn {
        uint256 lastBurnt;
        uint256 totalBurnt;
    }

    mapping(uint256 => Pool) public pools;
    mapping(bytes32 => bool) public expectingRequestWithIdToBeFulfilled;
    mapping(bytes32 => uint256) public expectingRequestWithIdToPool;
    mapping(bytes32 => uint256) public expectingRequestWithIdToRound;
    mapping(address => mapping(address => uint256)) public userBalance;
    mapping(address => uint256) public burnPool;
    mapping(address => uint256) public treasuryPool;
    mapping(address => uint256) public devPool;
    mapping(address => Burn) public burns;

    constructor(address _airnodeRrp) RrpRequesterV0(_airnodeRrp) {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner");
        _;
    }

    modifier onlyTreasury() {
        require(msg.sender == treasuryWallet, "Only Treasury");
        _;
    }

    modifier onlyDev() {
        require(msg.sender == devWallet, "Only dev");
        _;
    }

    function setFee(uint256 _fee) external onlyOwner {
        require(_fee <= 4, "exceed limit");
        require(_fee >= 2, "minimum fee");
        fee = _fee;
    }

    function transferOwnership(address _new) external onlyOwner {
        owner = _new;
    }

    function setTreasuryWallet(address _new) external onlyTreasury {
        treasuryWallet = _new;
    }

    function setDevWallet(address _new) external onlyDev {
        devWallet = _new;
    }

    // Set parameters used by airnodeRrp.makeFullRequest(...)
    // See makeRequestUint256()
    function setRequestParameters(
        address _airnode,
        bytes32 _endpointIdUint256,
        address _sponsorWallet,
        uint256 _sponsorBalance
    ) external onlyOwner {
        // Normally, this function should be protected, as in:
        // require(msg.sender == owner, "Sender not owner");
        airnode = _airnode;
        endpointIdUint256 = _endpointIdUint256;
        sponsorWallet = _sponsorWallet;
        sponsorBalance = _sponsorBalance;
    }

    // Calls the AirnodeRrp contract with a request
    // airnodeRrp.makeFullRequest() returns a requestId to hold onto.
    function draw(uint256 index, uint256 round) internal {
        uint256 remain = sponsorBalance - sponsorWallet.balance;
        if (remain > 0) {
            (bool success, ) = sponsorWallet.call{value: remain}("");
            treasuryPool[virtualFTMaddress] -= remain;
            require(success, "api3 fee");
        }

        bytes32 requestId = airnodeRrp.makeFullRequest(
            airnode,
            endpointIdUint256,
            address(this),
            sponsorWallet,
            address(this),
            this.fulfillUint256.selector,
            ""
        );
        // Store the requestId
        expectingRequestWithIdToBeFulfilled[requestId] = true;
        expectingRequestWithIdToPool[requestId] = index;
        expectingRequestWithIdToRound[requestId] = round;
    }

    // AirnodeRrp will call back with a response
    function fulfillUint256(bytes32 requestId, bytes calldata data)
        external
        onlyAirnodeRrp
    {
        // Verify the requestId exists
        require(expectingRequestWithIdToBeFulfilled[requestId], "not exist");
        expectingRequestWithIdToBeFulfilled[requestId] = false;
        uint256 index = expectingRequestWithIdToPool[requestId];
        uint256 round = expectingRequestWithIdToRound[requestId];
        uint256 random = uint256(
            keccak256(
                abi.encodePacked(
                    data,
                    pools[index].firstPlayers[round],
                    pools[index].secondPlayers[round]
                )
            )
        );
        pools[index].winners[round] = random % 2 == 1;
        address player;
        address tokenAddress = pools[index].tokenAddress;
        uint256 tokenAmount = pools[index].tokenAmount;
        if (random % 2 == 1) {
            player = pools[index].firstPlayers[round];
        } else {
            player = pools[index].secondPlayers[round];
        }
        userBalance[player][tokenAddress] += (tokenAmount * (200 - fee)) / 100;
        devPool[tokenAddress] += (tokenAmount * fee) / 400;
        treasuryPool[tokenAddress] += (tokenAmount * fee) / 400;
        burnPool[tokenAddress] += (tokenAmount * fee) / 200;
        api3Gas = sponsorBalance - sponsorWallet.balance;
    }

    function addPool(
        address _tokenAddress,
        uint256 _tokenAmount,
        bool _burning
    ) external onlyOwner {
        poolSize++;
        pools[poolSize].tokenAddress = _tokenAddress;
        pools[poolSize].tokenAmount = _tokenAmount;
        pools[poolSize].burning = _burning;
        pools[poolSize].status = true;
    }

    function togglePoolStatus(uint256 index) external onlyOwner {
        pools[index].status = !pools[index].status;
    }

    function getTokenAddress() public view returns (address[] memory) {
        uint256 uniqueCount;
        address[] memory data = new address[](poolSize);
        for (uint256 i = 1; i <= poolSize; i++) {
            bool check;
            for (uint256 j = 0; j < uniqueCount; j++) {
                if (data[j] == pools[i].tokenAddress) {
                    check = true;
                    break;
                }
            }
            if (check) continue;
            data[uniqueCount] = pools[i].tokenAddress;
            uniqueCount++;
        }

        address[] memory unique = new address[](uniqueCount);
        for (uint256 i = 0; i < uniqueCount; i++) {
            unique[i] = data[i];
        }
        return unique;
    }

    function enter(uint256 index) external payable {
        require(index != 0, "not exiting pool");
        require(index <= poolSize, "not exiting pool");
        require(pools[index].status, "not allowed");
        require(msg.value >= api3Gas, "not enough fee");
        require(
            userBalance[msg.sender][pools[index].tokenAddress] >=
                pools[index].tokenAmount,
            "Not enough balance"
        );
        treasuryPool[virtualFTMaddress] += msg.value;

        if (
            pools[index].firstPlayers.length ==
            pools[index].secondPlayers.length
        ) {
            pools[index].firstPlayers.push(msg.sender);
        } else {
            pools[index].secondPlayers.push(msg.sender);
            draw(index, pools[index].firstPlayers.length);
        }
    }

    function depositToken(address _tokenAddress, uint256 _amount) external {
        IERC20(_tokenAddress).transferFrom(msg.sender, address(this), _amount);
        userBalance[msg.sender][_tokenAddress] += _amount;
    }

    function deposit() external payable {
        userBalance[msg.sender][virtualFTMaddress] += msg.value;
    }

    function _transfer(
        address _tokenAddress,
        address _to,
        uint256 _amount
    ) internal {
        if (_tokenAddress != virtualFTMaddress)
            IERC20(_tokenAddress).transfer(_to, _amount);
        else {
            (bool sent, ) = _to.call{value: _amount}("");
            require(sent, "Ether not sent");
        }
    }

    function withdraw(address _tokenAddress, uint256 _amount)
        external
        nonReentrant
    {
        require(
            userBalance[msg.sender][_tokenAddress] >= _amount,
            "exceed amount"
        );
        userBalance[msg.sender][_tokenAddress] -= _amount;
        _transfer(_tokenAddress, msg.sender, _amount);
    }

    function withdrawAllFund() external nonReentrant {
        address[] memory unique = getTokenAddress();
        bool flag;
        for (uint256 i = 0; i < unique.length; i++) {
            address _tokenAddress = unique[i];
            uint256 _amount = userBalance[msg.sender][_tokenAddress];
            userBalance[msg.sender][_tokenAddress] -= _amount;
            if (_amount >= 0) {
                flag = true;
                _transfer(_tokenAddress, msg.sender, _amount);
            }
        }
        require(flag, "zero balance");
    }

    function claimTreasury(address _tokenAddress, uint256 _amount)
        external
        onlyTreasury
        nonReentrant
    {
        require(treasuryPool[_tokenAddress] >= _amount, "exceed amount");
        treasuryPool[_tokenAddress] -= _amount;
        _transfer(_tokenAddress, msg.sender, _amount);
    }

    function claimDev(address _tokenAddress, uint256 _amount)
        external
        onlyDev
        nonReentrant
    {
        require(devPool[_tokenAddress] >= _amount, "exceed amount");
        devPool[_tokenAddress] -= _amount;
        _transfer(_tokenAddress, msg.sender, _amount);
    }

    function claimTreasuryAll() external onlyTreasury nonReentrant {
        address[] memory unique = getTokenAddress();
        bool flag;
        for (uint256 i = 0; i < unique.length; i++) {
            address _tokenAddress = unique[i];
            uint256 _amount = treasuryPool[_tokenAddress];
            treasuryPool[_tokenAddress] -= _amount;
            if (_amount >= 0) {
                flag = true;
                _transfer(_tokenAddress, msg.sender, _amount);
            }
        }
        require(flag, "zero balance");
    }

    function claimDevAll() external onlyDev nonReentrant {
        address[] memory unique = getTokenAddress();
        bool flag;
        for (uint256 i = 0; i < unique.length; i++) {
            address _tokenAddress = unique[i];
            uint256 _amount = devPool[_tokenAddress];
            devPool[_tokenAddress] -= _amount;
            if (_amount >= 0) {
                flag = true;
                _transfer(_tokenAddress, msg.sender, _amount);
            }
        }
        require(flag, "zero balance");
    }

    function burn() external onlyOwner nonReentrant {
        bool flag = false;
        address[] memory unique = getTokenAddress();
        for (uint256 i = 0; i < unique.length; i++) {
            address _tokenAddress = unique[i];
            uint256 toBurn = burnPool[_tokenAddress];
            if (toBurn <= 0) continue;
            flag = true;
            burnPool[_tokenAddress] -= toBurn;
            burns[_tokenAddress].lastBurnt = toBurn;
            burns[_tokenAddress].totalBurnt += toBurn;
            IERC20Burnable(_tokenAddress).burn(burns[_tokenAddress].lastBurnt);
        }
        require(flag, "nothing to burn");
    }
}