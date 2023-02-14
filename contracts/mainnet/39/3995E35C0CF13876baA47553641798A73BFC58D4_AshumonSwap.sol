// SPDX-License-Identifier: MIT
pragma solidity ^0.8.5;

interface IAshumon {
    function mint(address to, uint256 amount) external;

    function burn(address account, uint256 amount) external;

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    function decimals() external returns (uint8);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);
}

pragma solidity ^0.8.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

pragma solidity ^0.8.0;

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        _transferOwnership(_msgSender());
    }

    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

pragma solidity ^0.8.1;

library Address {
    function isContract(address account) internal view returns (bool) {
        return account.code.length > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
    }

    function functionCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return
            functionCallWithValue(
                target,
                data,
                0,
                "Address: low-level call failed"
            );
    }

    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return
            functionCallWithValue(
                target,
                data,
                value,
                "Address: low-level call with value failed"
            );
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(
            address(this).balance >= value,
            "Address: insufficient balance for call"
        );
        (bool success, bytes memory returndata) = target.call{value: value}(
            data
        );
        return
            verifyCallResultFromTarget(
                target,
                success,
                returndata,
                errorMessage
            );
    }

    function functionStaticCall(address target, bytes memory data)
        internal
        view
        returns (bytes memory)
    {
        return
            functionStaticCall(
                target,
                data,
                "Address: low-level static call failed"
            );
    }

    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return
            verifyCallResultFromTarget(
                target,
                success,
                returndata,
                errorMessage
            );
    }

    function functionDelegateCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return
            functionDelegateCall(
                target,
                data,
                "Address: low-level delegate call failed"
            );
    }

    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return
            verifyCallResultFromTarget(
                target,
                success,
                returndata,
                errorMessage
            );
    }

    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage)
        private
        pure
    {
        if (returndata.length > 0) {
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}

pragma solidity ^0.8.0;

interface IERC20Permit {
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function nonces(address owner) external view returns (uint256);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

pragma solidity ^0.8.0;

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

pragma solidity ^0.8.0;

library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transfer.selector, to, value)
        );
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transferFrom.selector, from, to, value)
        );
    }

    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.approve.selector, spender, value)
        );
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(
                oldAllowance >= value,
                "SafeERC20: decreased allowance below zero"
            );
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(
                token,
                abi.encodeWithSelector(
                    token.approve.selector,
                    spender,
                    newAllowance
                )
            );
        }
    }

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(
            nonceAfter == nonceBefore + 1,
            "SafeERC20: permit did not succeed"
        );
    }

    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        bytes memory returndata = address(token).functionCall(
            data,
            "SafeERC20: low-level call failed"
        );
        if (returndata.length > 0) {
            require(
                abi.decode(returndata, (bool)),
                "SafeERC20: ERC20 operation did not succeed"
            );
        }
    }
}

pragma solidity ^0.8.5;

contract AshumonSwap is Ownable {
    using SafeERC20 for IAshumon;
    IAshumon public ashumonToken;
    address signerAddress;
    uint256 base = 10000000;

    // mapping to store payment methods
    mapping(uint8 => address) public paymentMethods;

    event TokenMinted(address, uint8, uint256, uint256);
    event TokenRedeemed(address, uint8, uint256, uint256);
    event SignerChanged(address);
    event BaseChanged(uint256);

    constructor(IAshumon tokenContract, address _signerAddress) {
        ashumonToken = tokenContract;
        signerAddress = _signerAddress;
        // ETH Mainnet addresses
        paymentMethods[1] = 0xdAC17F958D2ee523a2206206994597C13D831ec7; // USDT address
        paymentMethods[2] = 0x4Fabb145d64652a948d72533023f6E7A623C7C53; // BUSD address
        paymentMethods[3] = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48; // USDC address
        paymentMethods[4] = 0x6B175474E89094C44Da98b954EedeAC495271d0F; // DAI address
        paymentMethods[5] = 0x853d955aCEf822Db058eb8505911ED77F175b99e; // FRAX address
    }

    /*
     * mint tokens to the receiver address
     * user will receive equivalent tokens of amountIn
     * Requirements:
     * valid payment option
     * passed parameter amountIn must be greater than 0
     */
    function mintToken(
        uint8 paymentOption,
        uint256 amountIn,
        address receiver,
        uint256 ratio,
        uint256 deadline,
        bytes memory signature
    ) external {
        require(deadline > block.timestamp, "deadline Passed");

        require(
            paymentOption >= 1 && paymentOption <= 5,
            "Invalid payment Option"
        );
        require(amountIn > 100, "invalid amountIn");

        // validate signature authenticity
        require(
            verify(msg.sender, ratio, deadline, signature),
            "INVALID_SIGNATURE"
        );

        uint256 paymentAmount = ((((amountIn *
            decimal(IAshumon(paymentMethods[paymentOption]))) * ratio) /
            decimal(ashumonToken)) / base);
        require(paymentAmount > 100, "Invalid amount");
        SafeERC20.safeTransferFrom(
            IERC20(paymentMethods[paymentOption]),
            receiver,
            address(this),
            paymentAmount
        );

        ashumonToken.mint(receiver, amountIn);

        emit TokenMinted(receiver, paymentOption, paymentAmount, amountIn);
    }

    /*
     * redeem tokens to the receiver address
     * user will receive equivalent tokens of amountIn
     * Requirements:
     * valid redeem option
     * passed parameter amountIn must be greater than 0
     */

    function redeemToken(
        uint8 redeemOption,
        uint256 amountIn,
        address receiver,
        uint256 ratio,
        uint256 deadline,
        bytes memory signature
    ) external {
        require(deadline > block.timestamp, "deadline Passed");

        require(
            redeemOption >= 1 && redeemOption <= 5,
            "Invalid Redeem Option"
        );
        require(amountIn >= 100, "Invalid amountIn");

        // validate signature authenticity
        require(
            verify(msg.sender, ratio, deadline, signature),
            "INVALID_SIGNATURE"
        );

        ashumonToken.burn(receiver, amountIn);

        uint256 amountOut = (((amountIn *
            decimal(IAshumon(paymentMethods[redeemOption]))) * ratio) /
            decimal(ashumonToken) /
            base);

        require(amountOut > 0, "zero amountOut");
        SafeERC20.safeTransfer(
            IERC20(paymentMethods[redeemOption]),
            receiver,
            amountOut
        );

        emit TokenRedeemed(receiver, redeemOption, amountIn, amountOut);
    }

    /*
     * returns decimals of token passed in it as parameter
     */

    function decimal(IAshumon token) internal returns (uint256) {
        return 10**token.decimals();
    }

    //getting msg hash to generate signature off chian
    function getMessageHash(
        address receiver,
        uint256 ratio,
        uint256 deadline
    ) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(receiver, ratio, deadline));
    }

    //signer functioanlity
    function getEthSignedMessageHash(bytes32 _messageHash)
        public
        pure
        returns (bytes32)
    {
        /*
        Signature is produced by signing a keccak256 hash with the following format:
        "\x19Ethereum Signed Message\n" + len(msg) + msg
        */
        return
            keccak256(
                abi.encodePacked(
                    "\x19Ethereum Signed Message:\n32",
                    _messageHash
                )
            );
    }

    function verify(
        address receiver,
        uint256 ratio,
        uint256 deadline,
        bytes memory signature
    ) public view returns (bool) {
        bytes32 messageHash = getMessageHash(receiver, ratio, deadline);
        bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);

        return recoverSigner(ethSignedMessageHash, signature) == signerAddress;
    }

    function recoverSigner(
        bytes32 _ethSignedMessageHash,
        bytes memory _signature
    ) public pure returns (address) {
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);

        return ecrecover(_ethSignedMessageHash, v, r, s);
    }

    function splitSignature(bytes memory sig)
        public
        pure
        returns (
            bytes32 r,
            bytes32 s,
            uint8 v
        )
    {
        require(sig.length == 65, "invalid signature length");

        assembly {
            /*
            First 32 bytes stores the length of the signature
            add(sig, 32) = pointer of sig + 32
            effectively, skips first 32 bytes of signature
            mload(p) loads next 32 bytes starting at the memory address p into memory
            */

            // first 32 bytes, after the length prefix
            r := mload(add(sig, 32))
            // second 32 bytes
            s := mload(add(sig, 64))
            // final byte (first byte of the next 32 bytes)
            v := byte(0, mload(add(sig, 96)))
        }

        // implicitly return (r, s, v)
    }

    function setSignerAddress(address _address) external onlyOwner {
        signerAddress = _address;
        emit SignerChanged(_address);
    }

    function setBase(uint256 _base) external onlyOwner {
        require(_base > 1000000, "base should be greater than 1000000");
        base = _base;
        emit BaseChanged(_base);
    }
}