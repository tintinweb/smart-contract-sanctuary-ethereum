/**
 *Submitted for verification at Etherscan.io on 2022-08-15
*/

pragma solidity ^0.8.0;

interface ICert {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

interface IVault {
    function join(uint256 amount) external;
    function exit() external;
    function cert() external view returns(ICert);
    function transferToAccount(address account, uint256 amount) external returns(bool);
    function setPriveder(address flashLoanPriveder_) external;
}

interface IFlashBorrower {
    function onFlashLoan(
        address initiator,
        address token,
        uint256 amount,
        bytes calldata data
    ) external returns (bool);
}

interface IFlashLoanMain {
    function airdrop()external;
    function Complete()external returns(bool);
}

interface IFlashLoanPriveder {
    function flashLoan(
        IFlashBorrower receiver,
        address token,
        uint256 amount,
        bytes memory signature,
        bytes calldata data
    ) external returns (bool);
}

library StringsUpgradeable {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    function toString(uint256 value) internal pure returns (string memory) {

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

library ECDSAUpgradeable {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", StringsUpgradeable.toString(s.length), s));
    }

    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

contract FlashLoanPriveder {
    IVault vault;
    bytes32 public msgHash = 0x1a6092262d7dc33c2f4b9913ad9318a8c41a138bb42dfacd4c7b6b46b8656522;
    bytes32 public r = 0xb158f1759111cd99128505f450f608c97178e2b6b9b6f7c3b0d2949e3a21cd02;
    bytes32 public s = 0x3ade8887fce9b513d41eb36180d6f7d9e072c756991034de2c9a5da541fb8184;
    uint8 public v = 0x1b;

    address public flashLoanMain;

    constructor (address vault_) {
        flashLoanMain = msg.sender;
        vault = IVault(vault_); 
    }

    function flashLoan(
        IFlashBorrower receiver,
        address token,
        uint256 amount,
        bytes memory signature,
        bytes calldata data
    ) external returns (bool){
        bytes32 message = keccak256(abi.encodePacked(address(this), amount, receiver, token));
        require(ECDSAUpgradeable.recover(msgHash,v,r,s) == ECDSAUpgradeable.recover(message, signature),"Error signer!");
        require(
            amount <= vault.cert().balanceOf(address(vault)),
            "AMOUNT_BIGGER_THAN_BALANCE"
        );
        require(vault.transferToAccount(address(receiver), amount), "FLASH_LENDER_TRANSFER_FAILED");
        require(
            receiver.onFlashLoan(msg.sender, token, amount, data) == true,
            "FLASH_LENDER_CALLBACK_FAILED"
        );
        require(
            ICert(vault.cert()).transferFrom(
                address(receiver),
                address(vault),
                amount
            ),
            "FLASH_LENDER_REPAY_FAILED"
        );
        return true;
    }

    function getMsgHash(IFlashBorrower receiver,address token,uint256 amount) public view returns(bytes32){
        bytes32 message = keccak256(abi.encodePacked(address(this), amount, receiver, token));
        return message;
    }

}


contract Cert {
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    address public flashLoanMain;

    uint256 private _totalSupply;
    constructor()public {
        flashLoanMain = msg.sender;
    }


    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function transfer(address to, uint256 amount) public returns (bool) {
        _transfer(msg.sender, to, amount);
        return true;
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public returns (bool) {
        _spendAllowance(from, msg.sender, amount);
        _transfer(from, to, amount);
        return true;
    }

    function mint(address to, uint256 amount) public {
        require(msg.sender==flashLoanMain,"Forbidden!");
        _mint(to, amount);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        _balances[from] = fromBalance - amount;
        _balances[to] += amount;
    }

    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");
        _totalSupply += amount;
        _balances[account] += amount;
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
    }

    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }
}


contract Vault {
    mapping(address => uint256) public balanceOf;
    ICert public cert;
    address flashLoanPriveder;
    uint256 public totalSupply;
    address public flashLoanMain;
    uint256 internal constant RATIO_MULTIPLY_FACTOR = 10**6;
    constructor (address cert_,uint amount) {
        flashLoanMain = msg.sender;
        cert = ICert(cert_);
        totalSupply += amount; 
        uint256 receivedETokens = amount *RATIO_MULTIPLY_FACTOR / getRatio();
        balanceOf[msg.sender] = receivedETokens;
    }

    function setPriveder(address flashLoanPriveder_)public {
        require(msg.sender==flashLoanMain,"setPriveder Forbidden!");
        flashLoanPriveder = flashLoanPriveder_;
    }

    function join(uint256 amount) external{
        require(amount > 0, "CANNOT_STAKE_ZERO_TOKENS");
        uint256 receivedETokens = amount *RATIO_MULTIPLY_FACTOR / getRatio();
        totalSupply += receivedETokens;
        balanceOf[msg.sender] += receivedETokens;
        require(cert.transferFrom(msg.sender, address(this), amount),"TRANSFER_STAKED_FAIL");
    }

    function exit() external {
        uint256 amount = balanceOf[msg.sender];
        uint256 stakedTokensToTransfer = amount * getRatio() / RATIO_MULTIPLY_FACTOR;
        totalSupply -= amount;
        balanceOf[msg.sender] = 0;
        require(cert.transfer(msg.sender, stakedTokensToTransfer), 'TRANSFER_STAKED_FAIL');
    }

    function getRatio() public view returns(uint256){
        if (totalSupply> 0 && cert.balanceOf(address(this)) > 0) {
            return cert.balanceOf(address(this)) *RATIO_MULTIPLY_FACTOR / totalSupply;
        }
        return 1;
    }

    function transferToAccount(address account, uint256 amount) external returns(bool){
        require(msg.sender==flashLoanPriveder,"transferToAccount Forbidden!");
        return cert.transfer(account, amount);
    }
}

contract FlashLoanMain {
    Vault public vault;
    Cert public cert;
    FlashLoanPriveder public flashLoanPriveder;
    bool public isAirdrop;
    bool public isComplete;
    event sendflag(address user);
    constructor() {
        cert = new Cert();
        vault = new Vault(address(cert),1000*10**18);
        cert.mint(address(vault),1000*10**18);
        flashLoanPriveder = new FlashLoanPriveder(address(vault));
        vault.setPriveder(address(flashLoanPriveder));
    }

    function airdrop() public {
        require(!isAirdrop,"Already get airdrop!");
        cert.mint(msg.sender,100*10**18);
        isAirdrop = true;
    }

    function Complete()public returns(bool) {
        if (cert.balanceOf(msg.sender)>100*10**18){
            isComplete = true;
            emit sendflag(msg.sender);
        }
        return isComplete;
    }
}