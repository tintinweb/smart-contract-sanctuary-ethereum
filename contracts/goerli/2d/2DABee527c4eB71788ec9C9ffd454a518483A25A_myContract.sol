pragma solidity^0.8.4;

interface IERC20 {
    function balanceOf(address account) external view returns(uint256);

}

contract myContract {
    // returning balanceOf
    // 0xF759607ffee4B5482492927E51D3b7820DE4189d
    function check() external view returns(uint256) {
        address _userAddress = 0xF759607ffee4B5482492927E51D3b7820DE4189d;
        address _tokenAddress = 0xf2edF1c091f683E3fb452497d9a98A49cBA84666;
        uint256 balance = IERC20(_tokenAddress).balanceOf(_userAddress);
        return balance;
    }
}