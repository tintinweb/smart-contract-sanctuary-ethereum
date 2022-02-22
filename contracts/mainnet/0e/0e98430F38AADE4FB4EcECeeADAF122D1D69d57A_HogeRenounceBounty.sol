interface IHOGE {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function isExcluded(address account) external view returns (bool);
    function owner() external view returns (address);
}

contract HogeRenounceBounty {
	IHOGE HOGE = IHOGE(0xfAd45E47083e4607302aa43c65fB3106F1cd7607);
	address hogeMarketingWallet = 0xD11DD26465c036b45f4aDF9bEaEC9C798DD69923;

	function reincluded() public view returns (bool) {
		return !(HOGE.isExcluded(0x533e3c0e6b48010873B947bddC4721b1bDFF9648) 
			  || HOGE.isExcluded(0x0D0707963952f2fBA59dD06f2b425ace40b492Fe) 
			  || HOGE.isExcluded(0x39F6a6C85d39d5ABAd8A398310c52E7c374F2bA3));	
	}

	function renounced() public view returns (bool) {
		return (HOGE.owner() == address(0));
	}

	function complete() public {
		require(reincluded(), "Still addresses to include!");
		require(renounced(), "Now just need to renounce!");
		HOGE.transfer(hogeMarketingWallet, HOGE.balanceOf(address(this)));
	}
}