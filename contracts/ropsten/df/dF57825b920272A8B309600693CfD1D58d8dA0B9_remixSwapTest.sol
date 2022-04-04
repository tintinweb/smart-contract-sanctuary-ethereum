pragma solidity ^0.7.4;

interface IERC20 {
    function balanceOf(address owner) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transfer(address to, uint256 amount) external returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

interface IWETH is IERC20 {
    function deposit() external payable;

    function withdraw(uint256 wad) external;
}

//uint256 dai_approved;
contract remixSwapTest {
    uint256 dai_approved;

    constructor() public {
        dai_approved = 0;
    }

    IWETH public immutable WETH =
        IWETH(0x00c778417e063141139fce010982780140aa0cd5ab);
    IERC20 public immutable DAI =
        IERC20(0x00ad6d458402f60fd3bd25163575031acdce07538d);

    function withdraw_dai1() public payable {
        //Retirar dai desde el contrato a msg.sender
        DAI.transfer(msg.sender, DAI.balanceOf(address(this)));
    }

    function withdraw_weth1() public payable {
        //Retirar WETH desde el contrato a msg.sender
        WETH.transfer(msg.sender, WETH.balanceOf(address(this)));
    }

    //DEPOSIT//
    function deposit_dai1(uint256 amount) public payable {
        DAI.transferFrom(msg.sender, address(this), amount);
    }

    // function deposit_dai2(uint256 amount) public payable {
    //     DAI.transferFrom(msg.sender, address(this), amount);
    // }

    function deposit_weth1() public payable {
        //depositar WETH desde el contrato a msg.sender
        WETH.approve(msg.sender, type(uint256).max);
        WETH.transferFrom(
            msg.sender,
            address(this),
            WETH.balanceOf(msg.sender)
        );
    }

    ////////////APPROVE ////////////////////
    function check_DAI_allowance() external view returns (uint256 output) {
        return DAI.allowance(msg.sender, address(this));
    }

    function check_DAI_allowance2() external view returns (uint256 output) {
        require(
            DAI.allowance(msg.sender, address(this)) > 0,
            "FALLA ALLOWANCE"
        );
        return DAI.allowance(msg.sender, address(this));
    }

    function check_DAI_approve(
        address approveadr1,
        address allowadr1,
        address allowadr2,
        uint256 amount
    ) external payable returns (uint256 output) {
        //1000000000000000000
        require(DAI.approve(approveadr1, amount), "FALLA");
        require(DAI.allowance(allowadr1, allowadr2) > 0, "FALLA ALLOWANCE");
        return DAI.allowance(allowadr1, allowadr2);
    }

    function _deposit_DAI2(uint256 amount) external payable {
        //100000000000000000
        //1000000000000000000
        require(DAI.approve(msg.sender, amount), "FALLA1");
        require(DAI.approve(address(this), amount), "FALLA2");
        require(
            DAI.allowance(address(this), msg.sender) > 0,
            "FALLA ALLOWANCE"
        );
        DAI.transferFrom(msg.sender, address(this), amount);
        //dai_approved= DAI.allowance(address(this), msg.sender);
    }

    function check_DAI_approve1_get() public view returns (uint256 output) {
        return dai_approved;
    }

    function check_DAI_approve2() external {
        DAI.approve(address(this), 1000000000000000000);
    }

    function check_DAI_approve3(uint256 amount) external payable {
        require(DAI.approve(msg.sender, amount), "FALLA");
    }

    function check_DAI_approve4(uint256 amount) external payable {
        DAI.approve(msg.sender, amount);
    }

    function check_DAI_approve5() external payable returns (bool output) {
        return DAI.approve(msg.sender, type(uint256).max);
    }

    function check_DAI_approve6() public payable returns (bool output) {
        return DAI.approve(msg.sender, type(uint256).max);
    }

    function swapTokens(address recipient, uint256 amount) external {
        DAI.approve(msg.sender, amount);
        DAI.allowance(msg.sender, address(this));
        DAI.transferFrom(msg.sender, recipient, amount);
    }

    function swapTokens2(address recipient, uint256 amount) external {
        DAI.approve(msg.sender, amount);
        // DAI.allowance(msg.sender, address(this));
        require(
            DAI.allowance(msg.sender, address(this)) > 0,
            "FALLO ALLOWANCE"
        );
        DAI.transferFrom(msg.sender, recipient, amount);
    }

    function deposit_weth2(uint256 amount) public payable {
        require(amount > 0, "You need to sell at least some tokens");
        uint256 allowance = WETH.allowance(msg.sender, address(this));
        require(allowance >= amount, "Check the token allowance");
        //depositar WETH desde el contrato a msg.sender
        WETH.transferFrom(msg.sender, address(this), amount);
        payable(msg.sender).transfer(amount);
    }

    function deposit_weth3(uint256 amount) public payable {
        require(amount > 0, "You need to sell at least some tokens");
        uint256 allowance = WETH.allowance(msg.sender, address(this));
        require(allowance >= amount, "Check the token allowance");
        //depositar WETH desde el contrato a msg.sender
        WETH.transferFrom(msg.sender, address(this), amount);
    }

    function withdraw_all() public payable {
        withdraw_dai1();
        withdraw_weth1();
        withdraw_eth();
    }

    function deposit_eth1() public payable {
        //depositar WETH desde  msg.sender al contrato por msg.value
        //  WETH.deposit{value: msg.value}();
        WETH.deposit{value: msg.value}();
    }

    // function deposit_eth2(uint256 amount_) public payable {
    //     //depositar WETH desde  msg.sender al contrato por variable
    //     WETH.deposit{value: amount_}();
    // }

    // function withdraw_weth2() public payable {
    function withdraw_eth() public payable {
        //Retirar ETH desde el contrato a msg.sender
        msg.sender.transfer(address(this).balance);
    }

    function weth2eth_all() external {
        //cambiar de WETH a  contrato (ETH que se refleja en [address(this).balance])
        WETH.withdraw(WETH.balanceOf(address(this)));
    }

    function weth2eth(uint256 amount_) external {
        //cambiar de WETH a  contrato (ETH que se refleja en [address(this).balance])
        WETH.withdraw(amount_);
    }

    function weth2eth_value(uint256 amount) public payable {
        //cambiar de WETH a  contrato (ETH que se refleja en [address(this).balance])
        WETH.withdraw(msg.value);
    }

    function getDAIbalance() public view returns (uint256 amount) {
        //balance DAI de direccion del contrato
        return DAI.balanceOf(address(this));
    }

    function getDAI2balance() public view returns (uint256 amount) {
        //balance DAI  de msg.sender
        return DAI.balanceOf(msg.sender);
    }

    function getWethContractbalance() public view returns (uint256 amount) {
        //balance WETH en direccion del contrato
        return WETH.balanceOf(address(this));
    }

    function getWethSenderbalance() public view returns (uint256 amount) {
        //balance WETH en direccion del contrato
        return WETH.balanceOf(msg.sender);
    }

    function getETHContractbalance() public view returns (uint256 amount) {
        //balnce ETH en de la direccion del contrato [address(this).balance]
        return address(this).balance;
    }

    function getEthSenderbalance() public view returns (uint256 amount) {
        //balance ETH de msg.sender
        return msg.sender.balance;
    }

    function getAddressThis() public view returns (address) {
        return address(this);
    }
}