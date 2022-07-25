/**
 *Submitted for verification at Etherscan.io on 2022-07-25
*/

/**
 *Submitted for verification at Etherscan.io on 2022-07-14
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function decimals() external view returns (uint8);
  /**
   * @dev Returns the amount of tokens in existence.
   */
  function totalSupply() external view returns (uint256);

  /**
   * @dev Returns the amount of tokens owned by `account`.
   */
  function balanceOf(address account) external view returns (uint256);

  /**
   * @dev Moves `amount` tokens from the caller's account to `recipient`.
   *
   * Returns a boolean value indicating whether the operation succeeded.
   *
   * Emits a {Transfer} event.
   */
  function transfer(address recipient, uint256 amount) external returns (bool);

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
   * @dev Moves `amount` tokens from `sender` to `recipient` using the
   * allowance mechanism. `amount` is then deducted from the caller's
   * allowance.
   *
   * Returns a boolean value indicating whether the operation succeeded.
   *
   * Emits a {Transfer} event.
   */
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

// the base implementation contract for the bridge-contract


contract Bridge {

    enum Step {
        Burn,
        Mint
    }

    enum MintStatus {
        None,
        Pending,
        Accepted,
        Denied,
        Failed
    }

    struct MintInfo {
        MintStatus status;
        uint256 otherChainNonce;
        address receiver;
        uint256 amount;
        address _token;
        uint256 requestTime;
        uint256 signTime;
    }

    address public admin;
    uint256 public nonce;
    mapping(uint256 => bool) public processedTransactionNonces; // for storing the nonce process status using boolean and mapping
    mapping(address => bool) public blacklist;
    mapping(uint256 => MintInfo) public mintsInfo;

    mapping(address => uint256[]) public userMintNonces;
    uint256[] public globalMintNonces;
    uint256[] public pendingMintNonces;
    uint256[] public acceptedMintNonces;
    uint256[] public deniedMintNonces;
    uint256[] public failedMintNonces;

    event BurnEvent(
        uint256 indexed nonce,
        address from,
        address to,
        uint256 amount,
        address token,
        uint256 date
    );
    event MintRequest(
        uint256 indexed nonce,
        address _admin,
        address to,
        uint256 amount,
        address token,
        uint256 date
    );
    event MintAccepted(
        uint256 indexed nonce,
        address _admin,
        address to,
        uint256 amount,
        address token,
        uint256 date
    );
    event MintDenied(
        uint256 indexed nonce,
        address _admin,
        address to,
        uint256 amount,
        address token,
        uint256 date
    );
    event MintFailed(
        uint256 indexed nonce,
        address _admin,
        address to,
        uint256 amount,
        address token,
        uint256 date
    );
    event BlackListSet(
        address indexed _admin,
        address user,
        bool flag,
        uint256 date
    );
    event AdminTransfer(
        address indexed oldAdmin,
        address newAdmin,
        uint256 date
    );

    // initializing the bridge with the token contract and the admin address
    constructor () {
        admin = msg.sender;
    }

    // burn some amount of tokens
    function burn(uint256 _amount, address _token) public {
        IERC20(_token).transferFrom(msg.sender, address(this), _amount); // locking the tokens from the sender address in the contract
        emit BurnEvent(
            nonce,
            msg.sender,
            address(this),
            _amount,
            _token,
            block.timestamp
        );
        nonce++;
    }

    // function for minting some tokens the reciver

    function mint_request(
        uint256 otherChainNonce,
        address receiver,
        uint256 amount,
        address _token
    ) external {
        require(msg.sender == admin, "Only admin can ask mint tokens");
        require(
            processedTransactionNonces[otherChainNonce] == false,
            "transfer already processed"
        ); // checking if the nonce is already processed
        processedTransactionNonces[otherChainNonce] = true;

        mintsInfo[otherChainNonce].otherChainNonce = otherChainNonce;
        mintsInfo[otherChainNonce].status = MintStatus.Pending;
        mintsInfo[otherChainNonce].receiver = receiver;
        mintsInfo[otherChainNonce].amount = amount;
        mintsInfo[otherChainNonce]._token = _token;
        mintsInfo[otherChainNonce].requestTime = block.timestamp;

        globalMintNonces.push(otherChainNonce);
        userMintNonces[receiver].push(otherChainNonce);

        emit MintRequest(
            otherChainNonce,
            msg.sender,
            receiver,
            amount,
            _token,
            block.timestamp
        );

        if (blacklist[receiver]) {
            mintsInfo[otherChainNonce].status = MintStatus.Failed;
            mintsInfo[otherChainNonce].signTime = block.timestamp;
            failedMintNonces.push(otherChainNonce);

            emit MintFailed(
                otherChainNonce,
                msg.sender,
                receiver,
                amount,
                _token,
                block.timestamp
            );
        } else {
            pendingMintNonces.push(otherChainNonce);
        }
    }

    function mint_sign(
        uint256 _nonce,
        bool _sign
    ) external {
        require(msg.sender == admin, "Only admin can sign");
        require(mintsInfo[_nonce].status == MintStatus.Pending, "not Pending");

        if (_sign) {
            mintsInfo[_nonce].status = MintStatus.Accepted;
            mintsInfo[_nonce].signTime = block.timestamp;

            for (uint256 i = 0; i < pendingMintNonces.length; i++) {
                if (pendingMintNonces[i] == _nonce) {
                    pendingMintNonces[i] = pendingMintNonces[pendingMintNonces.length - 1];
                    pendingMintNonces.pop();
                    break;
                }
            }

            acceptedMintNonces.push(_nonce);

            IERC20(mintsInfo[_nonce]._token).approve(address(this),
                mintsInfo[_nonce].amount); // approving the amount of tokens to be minted
            IERC20(mintsInfo[_nonce]._token).transferFrom(address(this),
                mintsInfo[_nonce].receiver, mintsInfo[_nonce].amount); // minting some tokens for the receiver

            emit MintAccepted(
                mintsInfo[_nonce].otherChainNonce,
                msg.sender,
                mintsInfo[_nonce].receiver,
                mintsInfo[_nonce].amount,
                mintsInfo[_nonce]._token,
                block.timestamp
            );
        } else {
            mintsInfo[_nonce].status = MintStatus.Denied;
            mintsInfo[_nonce].signTime = block.timestamp;

            for (uint256 i = 0; i < pendingMintNonces.length; i++) {
                if (pendingMintNonces[i] == _nonce) {
                    pendingMintNonces[i] = pendingMintNonces[pendingMintNonces.length - 1];
                    pendingMintNonces.pop();
                    break;
                }
            }

            deniedMintNonces.push(_nonce);

            emit MintDenied(
                mintsInfo[_nonce].otherChainNonce,
                msg.sender,
                mintsInfo[_nonce].receiver,
                mintsInfo[_nonce].amount,
                mintsInfo[_nonce]._token,
                block.timestamp
            );
        }
        
    }

    function setBlacklist(address _address, bool _flag) external {
        require(msg.sender == admin, "Only admin can set blacklist");
        blacklist[_address] = _flag;
        
        emit BlackListSet(msg.sender, _address, _flag, block.timestamp);
    }

    function transferAdmin(address _address) external {
        require(msg.sender == admin, "Forbidden");
        admin = _address;

        emit AdminTransfer(msg.sender, _address, block.timestamp);
    }

    function viewGlobalMintNoncesLength() external view returns (uint256) {
        return globalMintNonces.length;
    }

    function viewUserMintNoncesLength(address _address) external view returns (uint256) {
        return userMintNonces[_address].length;
    }

    function viewPendingMintNoncesLength() external view returns (uint256) {
        return pendingMintNonces.length;
    }

    function viewAcceptedMintNoncesLength() external view returns (uint256) {
        return acceptedMintNonces.length;
    }

    function viewDeniedMintNoncesLength() external view returns (uint256) {
        return deniedMintNonces.length;
    }

    function viewFailedMintNoncesLength() external view returns (uint256) {
        return failedMintNonces.length;
    }

}