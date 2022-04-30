// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Lottery
 * @dev Implements voting process along with vote delegation
 */
contract Lottery {
    /* 
        [*] เหลือพวกเช็คว่าเป็นวันที่จริงหรือป่าว ตัวเลขจริงหรือป่าว  Period =>  (YYYYMMDD)
        [X] โอนเงินเมื่อถูกรางวัน
        [X] ออกเลข
        [X] listReward
        [X] ซื้อตามจะนวนเงินที่ระบุ
    */

    // กำหนดค่า
    uint256 private amountMax = 10; //เลขนั้นมีกี่ีใบ
    uint256 private limit = 5; //ซื้อได้สูงสุด 5 ใบ
    uint256 private LotteryMax = 2; //จำนวนตัวเลขของหวย ต่อเลข => (3 ==> 000-999), (2 ==> 00- 99)
    uint256 private price = 80 gwei; //ราคาหวย
    address public manager;

    constructor() {
        // กำหนดค่า
        manager = msg.sender;
    }

    //ข้อมูลผู้ใช้
    struct Buyer {
        string firstName;
        string lastName;
        string email;
        mapping(string => string[]) stockListLotteryByPeriod; //เอาไว้เก็บว่าเรานั้นซื้อเลขใดไปบ้าง โดยใช้เลขPeriod เป็น index
        string[] myPeriod; //เก็บว่าเราน้ันซื้อ Period ไหนไปบ้าง
    }
    mapping(address => Buyer) private buyerStruct;
    address[] private buyer_result; // เก็บ address ข้อมูลผู้ใช้ทั้งหมด
    // log
    event BuyerRegister(
        string firstName,
        string lastName,
        string email,
        address indexed BuyerAddress
    );

    function buyersRegister(
        string memory firstName,
        string memory lastName,
        string memory email
    ) public {
        // firstName, lastName, email ต้องไม่เป็นค่าว่าง
        require(
            (!checkStringEqualNull(firstName) &&
                !checkStringEqualNull(lastName) &&
                !checkStringEqualNull(email)),
            "Incomplete information"
        ); // ป้อนข้อมูลไม่ครบ

        // check ว่าลงทะเบียนไปแล้วหรือยัง
        require(
            checkStringEqualNull(buyerStruct[msg.sender].email),
            "Registered"
        );

        buyerStruct[msg.sender].firstName = firstName;
        buyerStruct[msg.sender].lastName = lastName;
        buyerStruct[msg.sender].email = email;
        emit BuyerRegister(firstName, lastName, email, msg.sender); // save log
        buyer_result.push(msg.sender);
    }

    function isRegistor() public view returns (bool) {
        return !checkStringEqualNull(buyerStruct[msg.sender].email);
    }

    modifier checkRegistor() {
        require(
            !checkStringEqualNull(buyerStruct[msg.sender].email),
            "Please register"
        );
        _;
    }

    function get_buyer_result() public view returns (address[] memory) {
        return buyer_result; // ดู address ของ buyer ทั้งหมด
    }

    function count_buyers() public view returns (uint256) {
        return buyer_result.length;
    }

    function getDetailBuyerByAddress(address address1)
        public
        view
        returns (
            string memory,
            string memory,
            string memory,
            string[] memory
        )
    {
        return (
            buyerStruct[address1].firstName,
            buyerStruct[address1].lastName,
            buyerStruct[address1].email,
            buyerStruct[address1].myPeriod
        );
    }

    function getMyDetailBuyer()
        public
        view
        returns (
            string memory,
            string memory,
            string memory,
            string[] memory
        )
    {
        return (
            buyerStruct[msg.sender].firstName,
            buyerStruct[msg.sender].lastName,
            buyerStruct[msg.sender].email,
            buyerStruct[msg.sender].myPeriod
        );
    }

    // ดูว่าแต่ละPeriod เรานั้นซื้อเลขอะไรไปบ้าง
    function getMyLotteryByPeriod(string memory period)
        public
        view
        returns (string[] memory)
    {
        return buyerStruct[msg.sender].stockListLotteryByPeriod[period];
    }

    //  Lottery
    struct Lottery_ {
        string lotteryNo; // หมายเลขหวย
        string period; // ช่วงวันที่
        uint256 amount;
        address[] listAddress; // address ของคนซื้อ
    }
    mapping(string => Lottery_) private lotteryStruct;
    mapping(string => string[]) private listPeriod; // เก็บว่าแต่ละ period มีเลขอะไรบ้าง
    string[] private period_result; // เก็บว่ามี period อะไรบ้าง
    mapping(string => address payable[]) private walletCommonMoney; //  walletกลองกลางของแต่ละงวด
    mapping(string => uint256) private commonMoney; // จำนวนเงินกลองกลางของแต่ละงวด

    // กำหนดค่าเริ่มต้น
    function generateLottery(string memory period) public {
        require(msg.sender == manager, "Only meneger");
        require(((bytes(period).length == 8)), "period Incorrect");

        if (listPeriod[period].length == 0) {
            // period นี้ถูก generate ไปแล้วหรือยัง
            period_result.push(period); // เก็บว่ามี period อะไรบ้าง
            for (uint256 i = 0; i < mathPow(LotteryMax); i++) {
                    string memory lotteryNo = "";
                if(LotteryMax==1){
                    lotteryNo = i == 0 ? "0" : uintToString(i); // fubction ที่แปลง uint to string มันมีปัญหาตจรงเลข 0
                }else{
                    lotteryNo= concatenate("0", uintToString(i)); /// PK
                }
               
                string memory _address = concatenate(lotteryNo, period); /// PK
                lotteryStruct[_address].lotteryNo = lotteryNo; // หมายเลขของหวย ที่ต้องการซื้อ
                lotteryStruct[_address].period = period; // งวดวันที่
                lotteryStruct[_address].amount = amountMax; // จำนวนว่ามีกี่ใบ
                lotteryStruct[_address].listAddress = new address[](0); // address ของคนซื้อ

                listPeriod[period].push(lotteryNo); // เก็บว่าแต่ละ period มีเลขอะไรบ้าง
            }
        }
    }

    function getPeriodAll() public view returns (string[] memory) {
        return period_result; //จะบอกว่า period อะไรบ้าง
    }

    function getPeriodDetail(string memory string1)
        public
        view
        returns (string[] memory)
    {
        return listPeriod[string1]; //จะบอกว่าแต่ละ period มีเลขอะไรบ้าง
    }

    function getLotteryDetailByAddress(
        string memory lotteryNo,
        string memory period
    ) public view returns (Lottery_ memory) {
        string memory _address = concatenate(lotteryNo, period); /// PK
        return lotteryStruct[_address];
    }

    // log
    event BuyingLottery(
        uint256 Amount,
        string Address,
        string Period,
        string Number,
        uint256 Money
    ); // amount ,  Addressของคนซื้อ, Period, number, Money

    function buyingLottery(string memory lotteryNo, string memory period)
        public
        payable
        checkRegistor
    {
        /*         
            // พวกการเช็คค่าต่างๆ ยังไม่ได้ทำ
            [*] ซื้อเกินlimit ต่อ period หรือไม่ 
            [*] มีเลขนี้อยู่ในระบบหรือไม่ ถ้าไม่มีให้สร้าง
            [*] จำนวน amountของเลขนั้นมันเกินหรือไม่ (เลขนี้หมดไปแล้ว)
        */

        require(!Award[period].isAwarding, "This Period sale has been closed"); // งวดนี้ปิดการขายไปแล้ว
        require(checkNumber(lotteryNo, period), "LotteryNo not found"); // check ว่าเลขนี้มีอยู่หรือป่าว
        string memory _address = concatenate(lotteryNo, period); /// PK

        //ซื้อเกินlimit ต่อ period หรือไม่
        if (
            buyerStruct[msg.sender].stockListLotteryByPeriod[period].length >=
            limit
        ) {
            require(false, "Lottery limit");
        }

        //เช็คว่าเลขนี้ยังซื้อได้อยู่
        if (lotteryStruct[_address].amount > 0) {
            //ยังมีเหลือ

            require(msg.value == price, "You must pay at least 80 gwei  ");
            //require(msg.value == 1 ether , "You must pay at least 1 ether  ");

            lotteryStruct[_address].amount = lotteryStruct[_address].amount - 1;
            lotteryStruct[_address].listAddress.push(msg.sender); // address ของคนซื้อ
            if (
                buyerStruct[msg.sender]
                    .stockListLotteryByPeriod[period]
                    .length == 0
            ) {
                buyerStruct[msg.sender].myPeriod.push(period);
            }
            buyerStruct[msg.sender].stockListLotteryByPeriod[period].push(
                lotteryNo
            );

            // โอนเข้ากลองกลาง
            walletCommonMoney[period].push(payable(msg.sender)); //โอนเงินเข้ากลองกลาง
            commonMoney[period] = commonMoney[period] + msg.value; // บันทึกว่ากลองกลางมีเงินจำนวนเท่าไหร่

            // save log
            emit BuyingLottery(1, _address, period, lotteryNo, msg.value);
        } else {
            //เลขนี้หมดไปแล้ว
            require(false, "LotteryNo so out");
        }
    }

    //check ว่าเลขนี้มีอยู่หรือป่าว
    function checkNumber(string memory lotteryNo, string memory period)
        public
        view
        returns (bool)
    {
        require(
            (!checkStringEqualNull(lotteryNo) && !checkStringEqualNull(period)),
            "Incomplete information"
        ); // ป้อนข้อมูลไม่ครบ
        require(
            ((bytes(lotteryNo).length == LotteryMax)),
            "LotteryNo Incorrect"
        );
        require(((bytes(period).length == 8)), "Period Incorrect");

        require(IsNumber(lotteryNo), "LotteryNo Incorrect"); // check ว่าเป็นตัวเลขจริงหรือป่าว
        require(IsNumber(period), "Period Incorrect"); // check ว่าเป็นตัววันที่จริงหรือป่าว => 20220421 (YYYYMMDD)

        string memory _address = concatenate(lotteryNo, period);
        if (checkStringEqual(lotteryStruct[_address].lotteryNo, lotteryNo)) {
            // เจอว่ามีเลขนี้อยู่นะ
            return true;
        } else {
            return false;
        }
    }

    //check ว่าเลขนี้มีอยู่หรือป่าวและยังซื้อได้อยู่หรือป่าว
    function checkNumberAndBuy(string memory lotteryNo, string memory period)
        public
        view
        returns (bool)
    {
        if (checkNumber(lotteryNo, period)) {
            string memory _address = concatenate(lotteryNo, period);
            if (lotteryStruct[_address].amount > 0) {
                return true;
            } else {
                return false;
            }
        } else {
            return false;
        }
    }

    // ออก รางวัล
    struct award {
        uint256 Balance; // จำนวนเงินทั้งหมด
        uint256 BalancePerAddress; // จำนวนเงินทั้งหมด มาหาร จำนวน address => ก็จะได้เป็นว่า address จะได้เงินจำนวนเท่าไหร่
        bool isAwarding; // true ออกไปแล้ว
        string lotteryStruct; // เลขที่ออก
        address[] listAddress; // address ของผู้ที่เคยถูกรางวัล
    }
    mapping(string => award) private Award; //เอาไว้ของว่างวดนี้ออก เลขอะไร ใครได้บ้าง เงินเท่าไหร่
    // log
    event Awarding(
        uint256 Balance,
        uint256 BalancePerAddress,
        string lotteryStruct,
        address[] listAddress
    );

    //  เงินกลองกลางของแต่าละงวด
    function getBalance(string memory period) public view returns (uint256) {
        return commonMoney[period];
    }

    // ออกสลาก
    function awarding(string memory period) public {
        require(msg.sender == manager, "Only meneger");
        require(((bytes(period).length == 8)), "Period Incorrect");
        if (listPeriod[period].length == 0) {
            require(false, "Period Incorrect");
        }
        require(!Award[period].isAwarding, "Awarded"); // ออกรางวัลไปแล้ว

        // เอาเฉพาะเลขที่ขายไปแล้วมา random
        // https://stackoverflow.com/questions/69038767/solidity-returnsstring-memory-wont-permit-return-of-string5
        uint256 num = 0;
        for (uint256 i = 0; i < listPeriod[period].length; i++) {
            string memory _address1 = concatenate(
                listPeriod[period][i],
                period
            ); /// PK
            //randomLotteryNo.push(_address1);
            if (lotteryStruct[_address1].amount != amountMax) {
                // มีการซื้อขายไปแล้ว
                num = num + 1;
            }
        }
        uint256 j = 0;
        string[] memory randomLotteryNo = new string[](num);
        for (uint256 i = 0; i < listPeriod[period].length; i++) {
            string memory _address1 = concatenate(
                listPeriod[period][i],
                period
            ); /// PK
            if (lotteryStruct[_address1].amount != amountMax) {
                // มีการซื้อขายไปแล้ว
                randomLotteryNo[j] = _address1;
                j = j + 1;
            }
        }

        uint256 random1 = random(num);
        uint256 Balance = getBalance(period); //จำนวนเงินทั้งหมด
        uint256 BalancePerAddress = Balance /
            lotteryStruct[randomLotteryNo[random1]].listAddress.length; //จำนวนเงินทั้งหมด มาหาร จำนวน address => ก็จะได้เป็นว่า address จะได้เงินจำนวนเท่าไหร่
        Award[period].isAwarding = true;
        Award[period].Balance = Balance;
        Award[period].BalancePerAddress = BalancePerAddress;
        Award[period].listAddress = lotteryStruct[randomLotteryNo[random1]]
            .listAddress; // address ของคนที่ถูกรางวัล
        Award[period].lotteryStruct = randomLotteryNo[random1]; // เลยขไหน งวดไหน

        // ทำการโอนเงิน
        for (
            uint256 i = 0;
            i < lotteryStruct[randomLotteryNo[random1]].listAddress.length;
            i++
        ) {
            for (uint256 k = 0; k < walletCommonMoney[period].length; k++) {
                if (
                    lotteryStruct[randomLotteryNo[random1]].listAddress[i] ==
                    walletCommonMoney[period][k]
                ) {
                    address payable winner;
                    winner = walletCommonMoney[period][k];
                    winner.transfer(BalancePerAddress); // โอนเงิน
                    k = walletCommonMoney[period].length + 1;
                }
            }
        }

        walletCommonMoney[period] = new address payable[](0);
        commonMoney[period] = 0;

        //save log
        emit Awarding(
            Balance,
            BalancePerAddress,
            randomLotteryNo[random1],
            lotteryStruct[randomLotteryNo[random1]].listAddress
        );
    }

    function getAward(string memory period) public view returns (award memory) {
        return Award[period];
    }

    //////// functuion help
    function concatenate(string memory a, string memory b)
        internal
        pure
        returns (string memory)
    {
        return string(abi.encodePacked(a, b));
    }

    function getMyaddress() public view returns (address) {
        return msg.sender;
    }

    function getMyBalance() public view returns (uint256) {
        return msg.sender.balance;
    }

    // string1==""
    function checkStringEqualNull(string memory string1)
        private
        pure
        returns (bool)
    {
        // string1==""
        if (bytes(string1).length == 0) {
            return true;
        }
        return false;
    }

    // string1== string2
    function checkStringEqual(string memory string1, string memory string2)
        private
        pure
        returns (bool)
    {
        if (
            keccak256(abi.encodePacked(string1)) ==
            keccak256(abi.encodePacked(string2))
        ) {
            return true;
        }
        return false;
    }

    // random number. 0-n
    function random(uint256 number) private view returns (uint256) {
        return
            uint256(
                keccak256(
                    abi.encodePacked(
                        block.timestamp,
                        block.difficulty,
                        msg.sender
                    )
                )
            ) % number;
    }

    function mathPow(uint256 number) private pure returns (uint256) {
        return 10**number;
    }

    // fubction ที่แปลง uint to string มันมีปัญหาตจรงเลข 0
    function uintToString(uint256 v) private pure returns (string memory) {
        uint256 maxlength = 100;
        bytes memory reversed = new bytes(maxlength);
        uint256 i = 0;
        while (v != 0) {
            uint256 remainder = v % 10;
            v = v / 10;
            reversed[i++] = bytes1(uint8(48 + remainder));
        }
        bytes memory s = new bytes(i); // i + 1 is inefficient
        for (uint256 j = 0; j < i; j++) {
            s[j] = reversed[i - j - 1]; // to avoid the off-by-one error
        }
        string memory str = string(s); // memory isn't implicitly convertible to storage
        return str;
    }

    function IsNumber(string memory str) private pure returns (bool) {
        bytes memory b = bytes(str);
        if (b.length > 13) return false;

        for (uint256 i; i < b.length; i++) {
            bytes1 char = b[i];

            if (
                !(char >= 0x30 && char <= 0x39) //9-0
            ) {
                return false;
            }
            /*         
                    if(
                        !(char >= 0x30 && char <= 0x39) && //9-0
                        !(char >= 0x41 && char <= 0x5A) && //A-Z
                        !(char >= 0x61 && char <= 0x7A) && //a-z
                        !(char == 0x2E) //.
                    ){
                        return false;
                    }
            */
        }

        return true;
    }
}