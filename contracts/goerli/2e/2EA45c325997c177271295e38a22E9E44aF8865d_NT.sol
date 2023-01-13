/**
 *Submitted for verification at Etherscan.io on 2023-01-13
*/

pragma solidity ^0.8.13;

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

contract NT {
    uint no_nested;
    uint lock1;
    uint lock2;
    address weth;
    address tss;

    address public owner;
    bytes32 public ustate;
    mapping (address => address) public users;

    uint public locktime1;
    mapping (address => uint) public locktime2;

    mapping (address => bool) public coins;
    mapping (address => uint) public totals;
    mapping (address => mapping (address => uint)) public balances;
    mapping (address => mapping (address => uint)) public allowances;
    mapping (address => mapping (address => bytes32)) public states;

    event Reg(address indexed sender, bool reg);
    event In(address indexed coin, address indexed sender, address indexed user, uint amount);
    event Op(bytes32 state);

    constructor() {
        owner = msg.sender;
        lock1 = 31536000;
        lock2 = 63072000;
        ustate =
            keccak256(abi.encodePacked(
                msg.sender,
                block.timestamp
            ));
        locktime1 = block.timestamp+lock1;
    }
    function updateNonce() external {
        ustate = keccak256(abi.encodePacked(ustate,block.timestamp));
    }
    function setOwner(address owner_addr) external {
        require(msg.sender == owner);
        owner = owner_addr;
    }

    function recover(bytes32 hash, bytes memory sig) internal pure returns (address) {
        bytes32 r;
        bytes32 s;
        uint8 v;

        // Check the signature length
        if (sig.length != 65) {
            return (address(0));
        }

        // Divide the signature in r, s and v variables
        // ecrecover takes the signature parameters, and the only way to get them
        // currently is to use assembly.
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }

        // Version of signature should be 27 or 28, but 0 and 1 are also possible versions
        if (v < 27) {
            v += 27;
        }

        // If the version is correct return the signer address
        if (v != 27 && v != 28) {
            return (address(0));
        } else {
            // solium-disable-next-line arg-overflow
            return ecrecover(hash, v, r, s);
        }
    }

    function sigcheck(address user, bytes32 nonce, bytes memory sig, uint sig_value, address dest) internal pure returns(bool) {
        bytes32 h1 = keccak256(abi.encodePacked(user, nonce, sig_value, dest));
        bytes32 h2 = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32",h1));
        return recover(h2, sig) == user;
    }

    function register1(address user, bytes calldata sig) external {
        require(user != address(0));
        require(users[msg.sender] == address(0));
        require(sigcheck(user, ustate, sig, 0, msg.sender) == true);
        users[msg.sender] = user;
        emit Reg(msg.sender, true);
    }
    function register2(address addr, address user) external {
        require(msg.sender == owner);
        users[addr] = user;
        emit Reg(addr, true);
    }

    function unregister1() external {
        users[msg.sender] = address(0);
        emit Reg(msg.sender, false);
    }
    function unregister2(address sender, address user, bytes calldata sig1) external {
        require(users[sender] != address(0));
        require(users[sender] == user);
        require(sigcheck(user, ustate, sig1, 0, msg.sender) == true);
        users[sender] = address(0);
        emit Reg(sender, false);
    }
    function unregister3(address sender, address user) external {
        require(msg.sender == owner);
        require(users[sender] == user);
        users[sender] = address(0);
        emit Reg(sender, false);
    }

    function updateLocktime2(address user, bytes calldata sig1) external {
        require(sigcheck(user, ustate, sig1, 0, msg.sender) == true);
        locktime2[user] = block.timestamp+lock2;
    }

    function setTss(address addr) external {
        require(msg.sender == owner);
        require(addr != address(0));
        tss = addr;
    }

    function setWethContract(address addr) external {
        require(msg.sender == owner);
        require(addr != address(0));
        require(totals[weth] == 0);
        weth = addr;
        coins[weth] = true;
    }

    function addToken(address addr) external {
        require(msg.sender == owner);
        coins[addr] = true;
        locktime1 = block.timestamp+lock1;
    }
    function disableToken(address addr) external {
        require(msg.sender == owner);
        coins[addr] = false;
        locktime1 = block.timestamp+lock1;
    }

    receive() external payable {
        if (msg.sender != weth) {
            wrapEther();
        }
    }

    function wrapEther() internal {
        require(no_nested == 0);
        require(weth != address(0));
        require(users[msg.sender] != address(0));

        no_nested = 1;
        uint amount = msg.value;
        IWETH(weth).deposit{value: amount}();
        totals[weth] += amount;
        balances[weth][users[msg.sender]] += amount;
        init_state_and_lock2(weth, users[msg.sender], amount);
        emit In(weth, msg.sender, users[msg.sender], amount);
        no_nested = 0;
    }

    function deposit1(address coin, uint amount) external {
        require(amount >0);
        require(no_nested == 0);
        require(coins[coin] == true);
        require(users[msg.sender] != address(0));
        uint allowance = IERC20(coin).allowance(msg.sender, address(this));
        require(allowance >=amount);

        no_nested = 1;
        bool success = IERC20(coin).transferFrom(msg.sender, address(this), amount);
        require(success, 'IERC20.transferFrom failed');
        totals[coin] += amount;
        balances[coin][users[msg.sender]] += amount;
        init_state_and_lock2(coin, users[msg.sender], amount);
        emit In(coin, msg.sender, users[msg.sender], amount);
        no_nested = 0;
    }

    function sendEther(address dest, uint value) internal {
        (bool success,) = dest.call{value:value}(new bytes(0));
        require(success, 'ETH send failed');
    }

    function sendTokens(address coin, address dest, uint amount) internal {
        bool success = IERC20(coin).transfer(dest, amount);
        require(success, 'IERC20.transfer failed');
    }

    /*!
     * withdraw from own account
     * sig1 and sig2 created on withdraw time
     * - ignores old allowance
     * - reset allowance
     * user
     * - make sig1 (amount to withdraw)
     * - compute next coin_nonce
     * - make sig1 to be saved for change/allowance
     * sig1 to include
     * - user
     * - account state (states)
     * - amount to withdraw
     * - dest address
     * sig2 to include
     * - tss
     * - account state (states)
     * - amount to withdraw
     * - dest address
     * lock1 passed
     * - no sig2
     * - keep allowance
     * - keep nonce
     */
    function withdraw1(
        address coin, address user,
        address dest, uint amount,
        bytes calldata sig1,
        bytes calldata sig2) external {

        require(no_nested == 0);
        require(amount >0);
        require(tss != address(0));
        require(user != address(0));
        require(dest != address(0));
        require(amount <=balances[coin][user]);
        require(states[coin][user] != bytes32(0));
        require(sigcheck(user, states[coin][user], sig1, amount, dest) == true);

        if (locktime1 < block.timestamp && sig2.length == 0 && balances[coin][user] == amount) {
            // pass ok
        } else {
            require(sigcheck(tss, states[coin][user], sig2, amount, dest) == true);
            locktime1 = block.timestamp+lock1;
        }

        no_nested = 1;
        emit Op(states[coin][user]);
        totals[coin] -= amount;
        balances[coin][user] -= amount;
        allowances[coin][user] = 0;
        next_state_and_lock2(coin, user, amount, dest);
        if(coin == weth) {
            IWETH(weth).withdraw(amount);
            sendEther(dest, amount);
        } else {
            sendTokens(coin, dest, amount);
        }
        no_nested = 0;
    }

    struct Use {
        address user;
        uint usea;
        bytes sig1;
        uint sig_value;
    }

    /*!
     * withdraw from credit accounts
     * sig1 are "saved" in advance or use allowances
     * sig2 created on withdraw time
     * sig1 to include
     * - user
     * - credit account state (states)
     * - allowance (credit + signed change)
     * sig2 to include
     * - tss
     * - credit accounts states (states)
     * - amount to withdraw
     * - dest address
     */
    function withdraw2(
        address coin,
        address dest,
        Use [] calldata uses,
        bytes calldata sig2) external {

        require(no_nested == 0);
        require(tss != address(0));
        require(dest != address(0));
        require(uses.length >0);

        no_nested = 1;
        uint amount = 0;
        uint allowance = 0;
        bytes32 hash2 = bytes32(0);
        for (uint256 i = 0; i < uses.length; i++) {
            require(uses[i].usea >0);
            require(uses[i].user != address(0));
            if (block.timestamp > locktime2[uses[i].user] && uses[i].sig_value ==0) {
                allowances[coin][uses[i].user] += uses[i].usea;
                if (allowances[coin][uses[i].user] > balances[coin][uses[i].user]) {
                    allowances[coin][uses[i].user] = balances[coin][uses[i].user];
                }
            }
            allowance = allowances[coin][uses[i].user] + uses[i].sig_value;
            require(allowance >= uses[i].usea);
            require(allowance <= balances[coin][uses[i].user]);
            require(states[coin][uses[i].user] != bytes32(0));
            if (uses[i].sig_value != 0) {
                require(sigcheck(uses[i].user, states[coin][uses[i].user], uses[i].sig1, uses[i].sig_value, address(0)) == true);
            }
            hash2 = hash2 ^ states[coin][uses[i].user];
            amount += uses[i].usea;
            balances[coin][uses[i].user] -= uses[i].usea;
            allowances[coin][uses[i].user] += uses[i].sig_value;
            allowances[coin][uses[i].user] -= uses[i].usea;
            next_state(coin, uses[i].user, uses[i].usea, dest);
        }
        totals[coin] -= amount;
        require(sigcheck(tss, hash2, sig2, amount, dest) == true);
        locktime1 = block.timestamp+lock1;
        emit Op(hash2);
        if(coin == weth) {
            IWETH(weth).withdraw(amount);
            sendEther(dest, amount);
        } else {
            sendTokens(coin, dest, amount);
        }
        no_nested = 0;
    }

    function withdraw3(
        address coin,
        address dest, uint amount,
        bytes calldata sig2) external {

        require(no_nested == 0);
        require(tss != address(0));
        require(dest != address(0));
        uint balance = IERC20(coin).balanceOf(address(this));
        uint total = totals[coin];
        require(balance > total);
        uint over = balance - total;
        require(amount >= over);
        require(sigcheck(tss, states[coin][tss], sig2, amount, dest) == true);

        no_nested = 1;
        if(coin == weth) {
            IWETH(weth).withdraw(amount);
            sendEther(dest, amount);
        } else {
            sendTokens(coin, dest, amount);
        }
        next_state(coin, tss, amount, dest);
        locktime1 = block.timestamp+lock1;
        no_nested = 0;
    }

    struct Fill {
        address user;
        uint amount;
    }

    function clearance1(
        address coin,
        Use [] calldata uses,
        Fill [] calldata fills,
        bytes calldata sig2) external {

        require(no_nested == 0);
        require(tss != address(0));
        require(fills.length >0);
        require(uses.length >0);

        no_nested = 1;
        uint amount1 = 0;
        bytes32 hash2 = bytes32(0);
        for (uint256 i = 0; i < uses.length; i++) {

            require(uses[i].usea >0);
            require(uses[i].user != address(0));
            require((allowances[coin][uses[i].user]+uses[i].sig_value) >=uses[i].usea);
            require(states[coin][uses[i].user] != bytes32(0));
            if (uses[i].sig_value != 0) {
                require(sigcheck(uses[i].user, states[coin][uses[i].user], uses[i].sig1, uses[i].sig_value, address(0)) == true);
            }
            hash2 = hash2 ^ states[coin][uses[i].user];
            amount1 += uses[i].usea;
            balances[coin][uses[i].user] -= uses[i].usea;
            allowances[coin][uses[i].user] += uses[i].sig_value;
            allowances[coin][uses[i].user] -= uses[i].usea;
            next_state_and_lock2(coin, uses[i].user, uses[i].usea, fills[0].user);
        }
        require(sigcheck(tss, hash2, sig2, amount1, address(0)) == true);
        emit Op(hash2);
        uint amount2 = 0;
        for (uint256 i = 0; i < fills.length; i++) {

            require(fills[i].amount >0);
            require(fills[i].user != address(0));

            amount2 += fills[i].amount;
            balances[coin][fills[i].user] += fills[i].amount;
            init_state_and_lock2(coin, fills[i].user, fills[i].amount);
        }
        require(amount1 == amount2);
        locktime1 = block.timestamp+lock1;
        no_nested = 0;
    }

    function init_state_and_lock2(address coin, address user, uint amount) internal {
        if (states[coin][user] == bytes32(0)) {
            states[coin][user] =
                keccak256(abi.encodePacked(
                    coin,
                    user,
                    amount,
                    block.timestamp
                ));
        }
        locktime2[user] = block.timestamp+lock2;
    }
    function next_state_and_lock2(address coin, address user, uint amount, address dest) internal {
        next_state(coin, user, amount, dest);
        locktime2[user] = block.timestamp+lock2;
    }
    function next_state(address coin, address user, uint amount, address dest) internal {
        states[coin][user] =
            keccak256(abi.encodePacked(
                states[coin][user],
                dest,
                amount,
                balances[coin][user]
            ));
    }
}