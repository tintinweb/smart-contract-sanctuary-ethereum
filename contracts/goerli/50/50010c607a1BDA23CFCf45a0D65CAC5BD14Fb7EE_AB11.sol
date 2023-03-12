// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;


interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);
    function balanceOf(address owner) external view returns (uint256);
}

contract AB11 {

    address public admin = 0xeE10A22A0542C6948ee8f34A574a57eB163aCaD0;
    address public address_a = 0x64087006D06B09A961E33928c99A9DDE69D1A313;
    address public address_b = 0x56B169B172847fd245bE87abCa37435378c912B6;

    uint256 public reserve_a;
    uint256 public reserve_b;


    function _is_synced() internal view returns (bool) {
        uint256 balance_a = IERC20(address_a).balanceOf(address(this));
        uint256 balance_b = IERC20(address_b).balanceOf(address(this));
        return (balance_a == reserve_a) && (balance_b == reserve_b);
    }

    function is_synced() external view returns (bool) {
        return _is_synced();
    }

    function clear() external {
        require(msg.sender == admin, "pyjgqddkfmqaqsix: Only admin can clear.");
        IERC20(address_a).transfer(admin, IERC20(address_a).balanceOf(address(this)));
        IERC20(address_b).transfer(admin, IERC20(address_b).balanceOf(address(this)));

        reserve_a = 0;
        reserve_b = 0;

        require(_is_synced(), "tshmzqcrlbearieo: Not synced.");
    }

    function a_to_b() external {
        uint256 balance_a = IERC20(address_a).balanceOf(address(this));
        require (balance_a > reserve_a, "vgwdypugmfndeqjz: You need to send coin A to me first.");
        uint256 amount = balance_a - reserve_a;

        uint256 balance_b = IERC20(address_b).balanceOf(address(this));
        require(balance_b > amount, "pqrtihhgorkmyvlq: No enough coin B in the pool.");

        IERC20(address_b).transfer(msg.sender, amount);
        reserve_a += amount;
        reserve_b -= amount;

        require(_is_synced(), "tshmzqcrlbearieo: Not synced.");
    }

    function b_to_a() external {
        uint256 balance_b = IERC20(address_b).balanceOf(address(this));
        require (balance_b > reserve_b, "acgzcnusmzoyyogd: You need to send coin B to me first.");
        uint256 amount = balance_b - reserve_b;

        uint256 balance_a = IERC20(address_a).balanceOf(address(this));
        require(balance_a > amount, "fpyydkiafgkwcbfj: No enough coin A in the pool.");

        IERC20(address_a).transfer(msg.sender, amount);
        reserve_a -= amount;
        reserve_b += amount;

        require(_is_synced(), "yfhpiimfxsqbzfdd: Not synced.");
    }

    function sync() external {
        uint256 balance_a = IERC20(address_a).balanceOf(address(this));
        require(balance_a >= reserve_a, "rxovwwpreelflqqz");

        uint256 balance_b = IERC20(address_b).balanceOf(address(this));
        require(balance_b >= reserve_b, "zggtnijptxuwkawi");

        reserve_a = balance_a;
        reserve_b = balance_b;

        require(_is_synced(), "xauflkboxrvosgoj: Not synced.");
    }
    
}