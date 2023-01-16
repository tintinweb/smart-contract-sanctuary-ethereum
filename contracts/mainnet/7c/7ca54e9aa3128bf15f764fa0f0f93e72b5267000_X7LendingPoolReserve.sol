/**
 *Submitted for verification at Etherscan.io on 2023-01-16
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

/*

 /$$   /$$ /$$$$$$$$       /$$$$$$$$ /$$
| $$  / $$|_____ $$/      | $$_____/|__/
|  $$/ $$/     /$$/       | $$       /$$ /$$$$$$$   /$$$$$$  /$$$$$$$   /$$$$$$$  /$$$$$$
 \  $$$$/     /$$/        | $$$$$   | $$| $$__  $$ |____  $$| $$__  $$ /$$_____/ /$$__  $$
  >$$  $$    /$$/         | $$__/   | $$| $$  \ $$  /$$$$$$$| $$  \ $$| $$      | $$$$$$$$
 /$$/\  $$  /$$/          | $$      | $$| $$  | $$ /$$__  $$| $$  | $$| $$      | $$_____/
| $$  \ $$ /$$/           | $$      | $$| $$  | $$|  $$$$$$$| $$  | $$|  $$$$$$$|  $$$$$$$
|__/  |__/|__/            |__/      |__/|__/  |__/ \_______/|__/  |__/ \_______/ \_______/

Contract: Smart Contract for minting and redeeming X7D and funding the Lending Pool with ETH.

This contract may be used to mint X7D and redeem X7D.

For ease of integration, contracts may choose to simply send ETH to this contract and they will receive X7D.
X7 ecosystem contracts that deposit funds in this manner have X7D minted to the X7 Token Time Lock.

However, it is recommended to use depositETH or depositETHForRecipient to guarantee that the X7D is only ever minted to the desired location.

A word of CAUTION for minters:

The full X7D ecosystem will evolve over time. While all ETH funds deposited to this contract will remain locked in X7 ecosystem smart contracts not all ETH will remain in THIS contract.
There is no risk for minting X7D on this contract - however, withdrawals will be on a first come/first serve basis. Some funds may be servicing loans.
the X7100 series tokens will eventually act as a liquidity sink and will backstop X7D redemptions if there is a temporary funding gap (due to outstanding loans).
You should NOT mint X7D from this contract unless you are willing to wait an indeterminate amount of time to withdraw your ETH on the first come/first serve basis.

This contract will NOT be renounced.

The following are the only functions that can be called on the contract that affect the contract:

    function setLendingPool(address lendingPool_) external onlyOwner {
        require(lendingPool != lendingPool_);
        address oldLendingPool = lendingPool;
        lendingPool = lendingPool_;

        emit LendingPoolSet(oldLendingPool, lendingPool_);
    }

    function setEcosystemRecipientAddress(address recipient) external onlyOwner {
        require(ecosystemRecipient != recipient);
        address oldRecipient = ecosystemRecipient;
        ecosystemRecipient = recipient;

        emit EcosystemRecipientSet(oldRecipient, recipient);
    }

    function setX7D(address X7DAddress) external onlyOwner {
        require(address(X7D) != X7DAddress);
        address oldX7D = address(X7D);
        X7D = IX7D(X7DAddress);

        emit X7DSet(oldX7D, X7DAddress);
    }

    function setEcosystemPayer(address ecosystemPayerAddress, bool value) external onlyOwner {
        require(isEcosystemPayer[ecosystemPayerAddress] != value);
        isEcosystemPayer[ecosystemPayerAddress] = value;

        emit EcosystemPayerSet(ecosystemPayerAddress, value);
    }

    function fundLendingPool(uint256 amount) external onlyOwner {
        require(lendingPool != address(0));
        require(amount <= address(this).balance);

        (bool success,) = lendingPool.call{value: amount}("");
        require(success);

        emit FundsSent(lendingPool, amount);
    }

    function setRecoveredTokenRecipient(address tokenRecipient_) external onlyOwner {
        require(recoveredTokenRecipient != tokenRecipient_);
        address oldRecipient = recoveredTokenRecipient;
        recoveredTokenRecipient = tokenRecipient_;

        emit RecoveredTokenRecipientSet(oldRecipient, tokenRecipient_);
    }

These functions will be passed to DAO governance once the ecosystem stabilizes.

*/

abstract contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor(address owner_) {
        _transferOwnership(owner_);
    }

    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    function _checkOwner() internal view virtual {
        require(owner() == msg.sender, "Ownable: caller is not the owner");
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
}

interface IX7D {
    function mint(address to, uint256 amount) external;
    function burn(address from, uint256 amount) external;
}

interface X7DMinter {
    // Call this function to explicitly mint X7D
    function depositETH() external payable;

    // Call this function to return ETH to this contract without minting X7D
    function returnETH() external payable;

    // Call this function to mint X7D to a recipient of your choosing
    function depositETHForRecipient(address recipient) external payable;
}

interface X7DBurner {
    // Call this function to redeem (burn) X7D for ETH
    function withdrawETH(uint256 amount) external;
}

abstract contract TokensCanBeRecovered is Ownable {
    bytes4 private constant TRANSFERSELECTOR = bytes4(keccak256(bytes('transfer(address,uint256)')));
    address public recoveredTokenRecipient;

    event RecoveredTokenRecipientSet(address oldRecipient, address newRecipient);

    function setRecoveredTokenRecipient(address tokenRecipient_) external onlyOwner {
        require(recoveredTokenRecipient != tokenRecipient_);
        address oldRecipient = recoveredTokenRecipient;
        recoveredTokenRecipient = tokenRecipient_;
        emit RecoveredTokenRecipientSet(oldRecipient, tokenRecipient_);
    }

    function recoverTokens(address tokenAddress) external {
        require(recoveredTokenRecipient != address(0));
        _safeTransfer(tokenAddress, recoveredTokenRecipient, IERC20(tokenAddress).balanceOf(address(this)));
    }

    function _safeTransfer(address token, address to, uint value) private {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(TRANSFERSELECTOR, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TRANSFER_FAILED');
    }
}

contract X7LendingPoolReserve is Ownable, TokensCanBeRecovered, X7DMinter, X7DBurner {
    IX7D public                     X7D;
    address public                  lendingPool;
    address public                  ecosystemRecipient;
    mapping(address => bool) public isEcosystemPayer;

    event X7DSet(address oldAddress, address newAddress);
    event EcosystemRecipientSet(address oldAddress, address newAddress);
    event EcosystemPayerSet(address payorAddress, bool isPayer);
    event LendingPoolSet(address oldAddress, address newAddress);
    event FundsSent(address indexed recipient, uint256 amount);
    event FundsReturned(address indexed sender, uint256 amount);

    constructor (address X7DAddress, address ecosystemRecipientAddress) Ownable(msg.sender) {
        X7D = IX7D(X7DAddress);
        ecosystemRecipient = ecosystemRecipientAddress;

        emit X7DSet(address(0), X7DAddress);
        emit EcosystemRecipientSet(address(0), ecosystemRecipientAddress);
    }

    receive () external payable {
        address recipient = msg.sender;

        if (isEcosystemPayer[msg.sender]) {
            recipient = ecosystemRecipient;
        }

        X7D.mint(recipient, msg.value);
    }

    function depositETH() external payable {
        X7D.mint(msg.sender, msg.value);
    }

    function depositETHForRecipient(address recipient) external payable {
        X7D.mint(recipient, msg.value);
    }

    function withdrawETH(uint256 amount) external {
        require(amount <= address(this).balance, "Insufficient funds to redeem that amount of X7D");
        X7D.burn(msg.sender, amount);
        (bool success,) = msg.sender.call{value: amount}("");
        require(success);
    }

    function returnETH() external payable {
        emit FundsReturned(msg.sender, msg.value);
    }

    function setLendingPool(address lendingPool_) external onlyOwner {
        require(lendingPool != lendingPool_);
        address oldLendingPool = lendingPool;
        lendingPool = lendingPool_;

        emit LendingPoolSet(oldLendingPool, lendingPool_);
    }

    function setEcosystemRecipientAddress(address recipient) external onlyOwner {
        require(ecosystemRecipient != recipient);
        address oldRecipient = ecosystemRecipient;
        ecosystemRecipient = recipient;

        emit EcosystemRecipientSet(oldRecipient, recipient);
    }

    function setX7D(address X7DAddress) external onlyOwner {
        require(address(X7D) != X7DAddress);
        address oldX7D = address(X7D);
        X7D = IX7D(X7DAddress);

        emit X7DSet(oldX7D, X7DAddress);
    }

    function setEcosystemPayer(address ecosystemPayerAddress, bool value) external onlyOwner {
        require(isEcosystemPayer[ecosystemPayerAddress] != value);
        isEcosystemPayer[ecosystemPayerAddress] = value;

        emit EcosystemPayerSet(ecosystemPayerAddress, value);
    }

    function fundLendingPool(uint256 amount) external onlyOwner {
        require(lendingPool != address(0));
        require(amount <= address(this).balance);

        (bool success,) = lendingPool.call{value: amount}("");
        require(success);

        emit FundsSent(lendingPool, amount);
    }
}