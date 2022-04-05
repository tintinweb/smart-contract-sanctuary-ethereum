/**
 *Submitted for verification at Etherscan.io on 2022-04-05
*/

pragma solidity ^0.8.12;


// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)
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

interface IFeeDB {
    event UpdateFeeAndRecipient(uint256 newFee, address newRecipient);
    event UpdatePaysFeeWhenSending(bool newType);
    event UpdateNFTDiscountRate(address nft, uint256 discountRate);
    event UpdateUserDiscountRate(address user, uint256 discountRate);

    function protocolFee() external view returns (uint256);

    function protocolFeeRecipient() external view returns (address);

    function paysFeeWhenSending() external view returns (bool);

    function userDiscountRate(address user) external view returns (uint256);

    function nftDiscountRate(address nft) external view returns (uint256);

    function getFeeDataForSend(address user, bytes calldata data)
        external
        view
        returns (
            bool _paysFeeWhenSending,
            address _recipient,
            uint256 _protocolFee,
            uint256 _discountRate
        );

    function getFeeDataForReceive(address user, bytes calldata data)
        external
        view
        returns (address _recipient, uint256 _discountRate);
}

interface IAPMReservoir {
    function token() external returns (address);

    event AddSigner(address signer);
    event RemoveSigner(address signer);
    event UpdateFeeDB(IFeeDB newFeeDB);
    event UpdateQuorum(uint256 newQuorum);
    event SendToken(
        address indexed sender,
        uint256 indexed toChainId,
        address indexed receiver,
        uint256 amount,
        uint256 sendingId,
        bool isFeePayed,
        uint256 protocolFee,
        uint256 senderDiscountRate
    );
    event ReceiveToken(
        address indexed sender,
        uint256 indexed fromChainId,
        address indexed receiver,
        uint256 amount,
        uint256 sendingId
    );
    event SetChainValidity(uint256 indexed chainId, bool status);
    event Migrate(address newReservoir);
    event TransferFee(address user, address feeRecipient, uint256 amount);

    function getSigners() external view returns (address[] memory);

    function signingNonce() external view returns (uint256);

    function quorum() external view returns (uint256);

    function feeDB() external view returns (IFeeDB);

    function signersLength() external view returns (uint256);

    function isSigner(address signer) external view returns (bool);

    function isValidChain(uint256 toChainId) external view returns (bool);

    function sendingData(
        address sender,
        uint256 toChainId,
        address receiver,
        uint256 sendingId
    )
        external
        view
        returns (
            uint256 amount,
            uint256 atBlock,
            bool isFeePayed,
            uint256 protocolFee,
            uint256 senderDiscountRate
        );

    function isTokenReceived(
        address sender,
        uint256 fromChainId,
        address receiver,
        uint256 sendingId
    ) external view returns (bool);

    function sendingCounts(
        address sender,
        uint256 toChainId,
        address receiver
    ) external view returns (uint256);

    function sendToken(
        uint256 toChainId,
        address receiver,
        uint256 amount,
        bytes calldata data
    ) external returns (uint256 sendingId);

    function receiveToken(
        address sender,
        uint256 fromChainId,
        address receiver,
        uint256 amount,
        uint256 sendingId,
        bool isFeePayed,
        uint256 protocolFee,
        uint256 senderDiscountRate,
        bytes calldata data,
        uint8[] calldata vs,
        bytes32[] calldata rs,
        bytes32[] calldata ss
    ) external;
}

library Signature {
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address signer) {
        require(
            uint256(s) <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0,
            "invalid signature 's' value"
        );
        require(v == 27 || v == 28, "invalid signature 'v' value");

        signer = ecrecover(hash, v, r, s);
        require(signer != address(0), "invalid signature");
    }
}

contract APMReservoir is IAPMReservoir {
    address[] private signers;
    mapping(address => uint256) private signerIndex;
    uint256 public signingNonce;
    uint256 public quorum;

    IFeeDB public feeDB;
    address public immutable token;

    constructor(
        address _token,
        uint256 _quorum,
        IFeeDB _feeDB,
        address[] memory _signers
    ) {
        require(_token != address(0), "invalid token address");
        token = _token;

        require(_quorum > 0, "invalid quorum");
        quorum = _quorum;
        emit UpdateQuorum(_quorum);

        require(_signers.length > _quorum, "signers should be more than quorum");
        signers = _signers;

        for (uint256 i = 0; i < _signers.length; i++) {
            address signer = _signers[i];
            require(signer != address(0), "invalid signer");
            require(signerIndex[signer] == 0, "already added");

            signerIndex[signer] = i + 1;
            emit AddSigner(signer);
        }

        require(address(_feeDB) != address(0), "invalid feeDB address");
        feeDB = _feeDB;
        emit UpdateFeeDB(_feeDB);

        isValidChain[8217] = true;
        emit SetChainValidity(8217, true);
    }

    function signersLength() external view returns (uint256) {
        return signers.length;
    }

    function isSigner(address signer) external view returns (bool) {
        return signerIndex[signer] != 0;
    }

    function getSigners() external view returns (address[] memory) {
        return signers;
    }

    function _checkSigners(
        bytes32 message,
        uint8[] memory vs,
        bytes32[] memory rs,
        bytes32[] memory ss
    ) private view {
        uint256 length = vs.length;
        require(length == rs.length && length == ss.length, "length is not equal");
        require(length >= quorum, "signatures should be quorum or more");

        address lastSigner;
        for (uint256 i = 0; i < length; i++) {
            address signer = Signature.recover(message, vs[i], rs[i], ss[i]);
            require(lastSigner < signer && signerIndex[signer] != 0, "invalid signer");
            lastSigner = signer;
        }
    }

    function addSigner(
        address signer,
        uint8[] calldata vs,
        bytes32[] calldata rs,
        bytes32[] calldata ss
    ) external {
        require(signer != address(0), "invalid signer parameter");
        require(signerIndex[signer] == 0, "already added");

        bytes32 hash = keccak256(abi.encodePacked("addSigner", block.chainid, address(this), signer, signingNonce++));
        bytes32 message = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
        _checkSigners(message, vs, rs, ss);

        signers.push(signer);
        signerIndex[signer] = signers.length;
        emit AddSigner(signer);
    }

    function removeSigner(
        address signer,
        uint8[] calldata vs,
        bytes32[] calldata rs,
        bytes32[] calldata ss
    ) external {
        require(signer != address(0), "invalid signer parameter");
        require(signerIndex[signer] != 0, "not added");

        bytes32 hash = keccak256(abi.encodePacked("removeSigner", block.chainid, address(this), signer, signingNonce++));
        bytes32 message = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
        _checkSigners(message, vs, rs, ss);

        uint256 lastIndex = signers.length - 1;
        require(lastIndex > quorum, "signers should be more than quorum");

        uint256 _signerIndex = signerIndex[signer];
        uint256 targetIndex = _signerIndex - 1;
        if (targetIndex != lastIndex) {
            address lastSigner = signers[lastIndex];
            signers[targetIndex] = lastSigner;
            signerIndex[lastSigner] = _signerIndex;
        }

        signers.pop();
        delete signerIndex[signer];

        emit RemoveSigner(signer);
    }

    function updateQuorum(
        uint256 newQuorum,
        uint8[] calldata vs,
        bytes32[] calldata rs,
        bytes32[] calldata ss
    ) external {
        require(newQuorum > 0 && newQuorum < signers.length, "invalid newQuorum parameter");

        bytes32 hash = keccak256(abi.encodePacked("updateQuorum", block.chainid, address(this), newQuorum, signingNonce++));
        bytes32 message = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
        _checkSigners(message, vs, rs, ss);

        quorum = newQuorum;
        emit UpdateQuorum(newQuorum);
    }

    function updateFeeDB(
        IFeeDB newDB,
        uint8[] calldata vs,
        bytes32[] calldata rs,
        bytes32[] calldata ss
    ) external {
        require(address(newDB) != address(0), "invalid newDB parameter");

        bytes32 hash = keccak256(abi.encodePacked("updateFeeDB", block.chainid, address(this), newDB, signingNonce++));
        bytes32 message = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
        _checkSigners(message, vs, rs, ss);

        feeDB = newDB;
        emit UpdateFeeDB(newDB);
    }

    struct SendingData {
        uint256 amount;
        uint256 atBlock;
        bool isFeePayed;
        uint256 protocolFee;
        uint256 senderDiscountRate;
    }
    mapping(address => mapping(uint256 => mapping(address => SendingData[]))) public sendingData;
    mapping(address => mapping(uint256 => mapping(address => mapping(uint256 => bool)))) public isTokenReceived;
    mapping(uint256 => bool) public isValidChain;

    function setChainValidity(
        uint256 chainId,
        bool isValid,
        uint8[] calldata vs,
        bytes32[] calldata rs,
        bytes32[] calldata ss
    ) external {
        bytes32 hash = keccak256(
            abi.encodePacked("setChainValidity", block.chainid, address(this), chainId, isValid, signingNonce++)
        );
        bytes32 message = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
        _checkSigners(message, vs, rs, ss);

        isValidChain[chainId] = isValid;
        emit SetChainValidity(chainId, isValid);
    }

    function sendingCounts(
        address sender,
        uint256 toChainId,
        address receiver
    ) external view returns (uint256) {
        return sendingData[sender][toChainId][receiver].length;
    }

    function sendToken(
        uint256 toChainId,
        address receiver,
        uint256 amount,
        bytes calldata data
    ) external returns (uint256 sendingId) {
        require(isValidChain[toChainId], "invalid toChainId parameter");
        require(receiver != address(0), "invalid receiver parameter");
        require(amount != 0, "invalid amount parameter");

        (bool paysFee, address feeRecipient, uint256 protocolFee, uint256 senderDiscountRate) = feeDB.getFeeDataForSend(
            msg.sender,
            data
        );

        sendingId = sendingData[msg.sender][toChainId][receiver].length;
        sendingData[msg.sender][toChainId][receiver].push(
            SendingData({
                amount: amount,
                atBlock: block.number,
                isFeePayed: paysFee,
                protocolFee: protocolFee,
                senderDiscountRate: senderDiscountRate
            })
        );
        _takeAmount(paysFee, feeRecipient, protocolFee, senderDiscountRate, amount);
        emit SendToken(msg.sender, toChainId, receiver, amount, sendingId, paysFee, protocolFee, senderDiscountRate);
    }

    function receiveToken(
        address sender,
        uint256 fromChainId,
        address receiver,
        uint256 amount,
        uint256 sendingId,
        bool isFeePayed,
        uint256 protocolFee,
        uint256 senderDiscountRate,
        bytes memory data,
        uint8[] memory vs,
        bytes32[] memory rs,
        bytes32[] memory ss
    ) public {
        require(!isTokenReceived[sender][fromChainId][receiver][sendingId], "already received");
        {
            bytes32 hash = keccak256(
                abi.encodePacked(
                    address(this),
                    fromChainId,
                    sender,
                    block.chainid,
                    receiver,
                    amount,
                    sendingId,
                    isFeePayed,
                    protocolFee,
                    senderDiscountRate
                )
            );
            bytes32 message = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
            _checkSigners(message, vs, rs, ss);
        }
        isTokenReceived[sender][fromChainId][receiver][sendingId] = true;
        _giveAmount(receiver, amount, isFeePayed, protocolFee, senderDiscountRate, data);

        emit ReceiveToken(sender, fromChainId, receiver, amount, sendingId);
    }

    function _takeAmount(
        bool paysFee,
        address feeRecipient,
        uint256 protocolFee,
        uint256 discountRate,
        uint256 amount
    ) private {
        require(protocolFee < 100 && discountRate <= 10000, "invalid feeData");
        if (paysFee && feeRecipient != address(0)) {
            uint256 feeAmount = (amount * ((protocolFee * (10000 - discountRate)) / 10000)) / 10000;
            if (feeAmount != 0) {
                IERC20(token).transferFrom(msg.sender, feeRecipient, feeAmount);
                emit TransferFee(msg.sender, feeRecipient, feeAmount);
            }
        }
        IERC20(token).transferFrom(msg.sender, address(this), amount);
    }

    function _giveAmount(
        address receiver,
        uint256 amount,
        bool isFeePayed,
        uint256 protocolFee,
        uint256 senderDiscountRate,
        bytes memory data
    ) private {
        uint256 feeAmount;
        require(protocolFee < 100 && senderDiscountRate <= 10000, "invalid feeDate");
        if (!isFeePayed && protocolFee != 0 && senderDiscountRate != 10000) {
            (address feeRecipient, uint256 receiverDiscountRate) = feeDB.getFeeDataForReceive(receiver, data);

            if (feeRecipient != address(0) && receiverDiscountRate != 10000) {
                uint256 maxDiscountRate = senderDiscountRate > receiverDiscountRate
                    ? senderDiscountRate
                    : receiverDiscountRate;
                feeAmount = (amount * ((protocolFee * (10000 - maxDiscountRate)) / 10000)) / 10000;

                if (feeAmount != 0) {
                    IERC20(token).transfer(feeRecipient, feeAmount);
                    emit TransferFee(receiver, feeRecipient, feeAmount);
                }
            }
        }
        IERC20(token).transfer(receiver, amount - feeAmount);
    }

    function migrate(
        address newReservoir,
        uint8[] calldata vs,
        bytes32[] calldata rs,
        bytes32[] calldata ss
    ) external {
        require(newReservoir != address(0), "invalid newReservoir parameter");

        bytes32 hash = keccak256(abi.encodePacked("migrate", block.chainid, address(this), newReservoir, signingNonce++));
        bytes32 message = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
        _checkSigners(message, vs, rs, ss);

        uint256 ethBalance = address(this).balance;
        if (ethBalance > 0) {
            (bool success, ) = payable(newReservoir).call{value: ethBalance}("");
            require(success, "eth transfer failure");
        }

        uint256 ApmBalance = IERC20(token).balanceOf(address(this));
        if (ApmBalance > 0) IERC20(token).transfer(newReservoir, ApmBalance);

        emit Migrate(newReservoir);
    }
}