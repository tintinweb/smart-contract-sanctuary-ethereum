// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ERC20 {
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function transfer(
        address recipient,
        uint256 amount
    ) external returns (bool);

    function balanceOf(address account) external view returns (uint256);
}

interface NO_STANDARD_ERC20 {
    function transferFrom(address from, address to, uint value) external;

    function transfer(address to, uint value) external;
}

interface WETH {
    function deposit() external payable;

    function withdraw(uint256 amount) external;

    function transfer(address to, uint256 amount) external returns (bool);
}

contract BRCEVMVault {
    address public admin;

    address public wethAddress;
    mapping(address => bool) public whitelistToken;
    mapping(address => bool) public isNoStandardERC20;
    mapping(bytes32 => bool) public usedTxids;

    // Deposit token
    event Deposit(
        address indexed from,
        address indexed to,
        address indexed tokenAddress,
        uint256 amount
    );

    // Withdraw token
    event Withdraw(
        address indexed to,
        address indexed tokenAddress,
        uint256 amount,
        bytes32 txid
    );

    // Withdraw token
    event AdminChanged(address indexed admin, address indexed newAdmin);

    constructor(address _wethAddress) {
        admin = msg.sender;
        wethAddress = _wethAddress;
        whitelistToken[_wethAddress] = true;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can call this function");
        _;
    }

    receive() external payable {}

    function changeAdmin(address newAdmin) public onlyAdmin {
        require(newAdmin != address(0), "Invalid address");
        emit AdminChanged(admin, newAdmin);
        admin = newAdmin;
    }

    function setWETHAddress(address _wethAddress) public onlyAdmin {
        wethAddress = _wethAddress;
        whitelistToken[_wethAddress] = true;
    }

    function setNoStandardERC20(address tokenAddress) public onlyAdmin {
        isNoStandardERC20[tokenAddress] = true;
    }

    function removeNoStandardERC20(address tokenAddress) public onlyAdmin {
        isNoStandardERC20[tokenAddress] = false;
    }

    function setWhitelistToken(
        address[] memory tokenAddresses
    ) public onlyAdmin {
        for (uint256 i = 0; i < tokenAddresses.length; i++) {
            whitelistToken[tokenAddresses[i]] = true;
        }
    }

    function removeWhitelistToken(
        address[] memory tokenAddresses
    ) public onlyAdmin {
        for (uint256 i = 0; i < tokenAddresses.length; i++) {
            whitelistToken[tokenAddresses[i]] = false;
        }
    }

    function deposit(
        address tokenAddress,
        address to,
        uint256 amount
    ) public payable {
        if (tokenAddress == address(0)) {
            WETH weth = WETH(wethAddress);
            weth.deposit{value: msg.value}();

            emit Deposit(msg.sender, to, wethAddress, msg.value);
        } else {
            require(
                whitelistToken[tokenAddress],
                "Token address is not whitelisted"
            );

            if (isNoStandardERC20[tokenAddress]) {
                NO_STANDARD_ERC20(tokenAddress).transferFrom(
                    msg.sender,
                    address(this),
                    amount
                );
            } else {
                require(
                    ERC20(tokenAddress).transferFrom(
                        msg.sender,
                        address(this),
                        amount
                    ),
                    "Token transfer failed"
                );
            }

            emit Deposit(msg.sender, to, tokenAddress, amount);
        }
    }

    function withdraw(
        address tokenAddress,
        address to,
        uint256 amount,
        bytes32 txid
    ) public onlyAdmin {
        require(
            whitelistToken[tokenAddress],
            "Token address is not whitelisted"
        );

        require(!usedTxids[txid], "Txid used");

        if (wethAddress == tokenAddress) {
            WETH weth = WETH(tokenAddress);
            weth.withdraw(amount);
            (bool success, ) = to.call{value: amount}("");
            require(success, "Token transfer failed");
        } else {
            if (isNoStandardERC20[tokenAddress]) {
                NO_STANDARD_ERC20(tokenAddress).transfer(to, amount);
            } else {
                require(
                    ERC20(tokenAddress).transfer(to, amount),
                    "Token transfer failed"
                );
            }
        }

        usedTxids[txid] = true;

        emit Withdraw(to, tokenAddress, amount, txid);
    }
}