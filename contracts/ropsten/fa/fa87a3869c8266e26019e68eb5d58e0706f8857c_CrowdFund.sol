/**
 *Submitted for verification at Etherscan.io on 2022-08-08
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;
// import "./IERC20.sol";这里引入与否都ok，因为下面写了接口合约
/* 众筹 ERC20 代币

用户创建活动。
用户可以承诺，将他们的代币转移到一个活动中。
活动结束后，如果承诺的总金额超过活动目标，活动创建者可以领取资金。
否则，活动没有达到目标，用户可以撤回承诺。 */
interface IERC20 {
    function transfer(address, uint) external returns (bool);

    function transferFrom(
        address,
        address,
        uint
    ) external returns (bool);
}


contract CrowdFund {
    event Launch/*事件类型*//*表示当前有一个众筹活动已经被创建出来了*//*事件的第一个字母大写*/(
        uint id/*uint*//*这次众筹活动的id，来自计数器count*/,
        address indexed/*可以在事件中索引查询到当前的创建者曾经创建过多少个活动id*/ creator/*地址类型*//*众筹的创建者地址*/,
        uint goal/*uint*//*众筹的token数量目标*/,
        uint32 startAt/*uint*//*众筹开始时间*/,
        uint32 endAt/*uint*//*众筹结束时间*/
    );
    event Cancel/*事件类型*/(uint id/*uint*//*众筹活动的id*/);
    event Pledge/*事件类型*//*这个事件代表有用户参与到众筹中了*/(uint indexed/*加过索引的参数必须要满足一个条件，你用这个索引肯定能查出来很多的值，所以你才会给它加上索引*/id/*uint*//*众筹活动的id*/, address indexed caller/*地址类型*//*这条消息的发送者msg.sender*//*当前用户地址*/, uint amount/*uint*//*这次众筹的新参与进来的token数量*/);
    event Unpledge/*事件类型*//*这个事件代表有用户撤销众筹了*/(uint indexed/*加过索引的参数必须要满足一个条件，你用这个索引肯定能查出来很多的值，所以你才会给它加上索引*/ id/*uint*//*众筹活动的id*/, address indexed caller/*地址类型*//*这条消息的发送者msg.sender*//*当前用户地址*/, uint amount/*uint*//*这次众筹的用户反悔减少的token数量*/);
    event Claim/*事件类型*//*这个事件代表众筹的token已被领取了*/(uint id/*uint*//*众筹活动的id*/);
    event Refund/*事件类型*//*代表用户取回了参与众筹的token数量*/(uint id/*uint*//*众筹活动的id*/, address indexed caller/*地址类型*//*这条消息的发送者msg.sender*//*当前用户地址*/, uint amount/*uint*//*当前用户在某一个众筹id活动之下的参与众筹的总的token数量*/);

    struct Campaign/*结构体类型*//*众筹活动*/  {
        // Creator of campaign
        address creator;/*地址类型*//*众筹的创建者地址*/
        // Amount of tokens to raise
        uint goal;/*uint*//*众筹的token数量目标*/
        // Total amount pledged
        uint pledged/*uint*//*已经有多少众筹的token数量参与进来*/;
        // Timestamp of start of campaign
        uint32/*开始时间和结束时间都是时间戳，uint32格式完全装的下*/ startAt;/*uint*//*众筹开始时间*/
        // Timestamp of end of campaign
        uint32 endAt;/*uint*//*众筹结束时间*/
        // True if goal was reached and creator has claimed the tokens.
        bool claimed/*bool类型*//*众筹的token是否已被领取*//*true状态表示众筹的token已经被创建者领走*//*false状态表示众筹的token没有被创建者领走*/;//一次众筹成功后创建者只能领取一次它筹款的数量
    }

    IERC20/*接口合约*/ public immutable token/*地址类型*//*IERC20接口合约地址*//*token作为IERC20接口合约的地址类型，具有使用该接口合约的函数方法tranferFrom*/;
    // Total count of campaigns created.
    // It is also used to generate id for new campaigns.
    uint public count/*uint*//*计数器：标记当前合约中共有多少个众筹活动存在*/;
    // Mapping from id to Campaign
    mapping/*在这个映射中可以通过众筹活动的id找到一个众筹结构体的详细数据*/(uint/*众筹活动的id*//*这个映射从1开始映射对应到它的结构体*/=> Campaign/*结构体类型*//*众筹活动*/) public campaigns/*映射类型*//*众筹活动*/;
    // Mapping from campaign id => pledger => amount pledged
    mapping/*嵌套映射*/(uint/*众筹活动的id*/=> mapping(address/*参与这次众筹活动的参与者地址*/ => uint/*参与者参与众筹活动的token数额*/)) public pledgedAmount/*映射类型*//*承诺的数量*/;

    //到这里，这次合约的数据结构基本已经做好了

    constructor/*规定当前合约只能使用哪个token的地址*/(address _token/*地址类型*//*输入的地址*/) {
        token/*地址类型*//*IERC20接口合约地址*/ /*这里token address等于输入变量_token*/= IERC20/*接口合约*/ (_token);//把地址类型转变为IERC20的合约类型
    }

    //下面是具体业务逻辑
    function launch/*函数名*//*创建一个众筹*/(
        uint _goal/*uint*//*众筹的token数量目标*/,
        uint32 _startAt/*uint*//*众筹开始时间*/,
        uint32 _endAt/*uint*//*众筹结束时间*/
    ) external {
        require/*要求众筹开始时间大于等于当前区块时间戳*/(_startAt/*uint*//*众筹开始时间*/>= block.timestamp/*uint类型*//*当前区块时间戳*//*这个时间不是一个准确的真实的时间戳，这个时间只在挖矿之后才会产生，所以它是固定的未来的一个时间点*/,unicode"众筹开始时间小于当前区块时间");
        require/*要求结束时间大于等于开始时间*/(_endAt/*uint*//*众筹结束时间*/>= _startAt/*uint*//*众筹开始时间*/, unicode"结束时间小于开始时间");
        require/*/*要求结束时间在当前区块时间戳的90天内*/(_endAt/*uint*//*众筹结束时间*/<= block.timestamp/*uint类型*//*当前区块时间戳*/+ 90 days, unicode"结束时间大于最大拍卖时间 end at > max duration");

        count/*uint*//*计数器：标记当前合约中共有多少个众筹活动存在*//*它的计数从1开始*/+= 1;
        campaigns/*结构体类型*//*Campaign结构体的实例*/[count] = Campaign/*结构体类型*//*众筹活动*/({//结构体的写法
            creator/*地址类型*//*众筹的创建者地址*/: msg.sender/*地址类型*//*这条消息的发送者*//*众筹合约的部署者*/,
            goal/*uint*//*众筹的token数量目标*/: _goal/*uint*//*众筹的token数量目标*/,
            pledged/*uint*//*已经有多少众筹的token数量参与进来*/: 0,
            startAt/*uint*//*众筹开始时间*/: _startAt/*uint*//*众筹开始时间*/,
            endAt/*uint*//*众筹结束时间*/: _endAt/*uint*//*众筹结束时间*/,
            claimed/*bool类型*//*众筹的token是否已被领取*//*true状态表示众筹的token已经被创建者领走*//*false状态表示众筹的token没有被创建者领走*/: false
        });

        emit Launch/*事件类型*//*表示当前有一个众筹活动已经被创建出来了*/(count/*uint*//*计数器：标记当前合约中共有多少个众筹活动存在*//*它的计数从1开始*/, msg.sender/*地址类型*//*这条消息的发送者*//*众筹合约的部署者*/, _goal/*uint*//*众筹的token数量目标*/, _startAt/*uint*//*众筹开始时间*/, _endAt/*uint*//*众筹结束时间*/);
    }

    function cancel/*函数名*//*众筹创建者可以在众筹开始之前取消众筹*/(uint _id/*uint*//*众筹活动的id*/) external {
        Campaign memory campaign/*结构体的实例campaign可以拥有该结构体的属性，用campaig.来表达*/= campaigns/*结构体类型*//*Campaign结构体的实例*/[_id];//先把活动结构体装到内存中，然后进行确认工作
        require/*要求这个众筹合约id的创建者和这条消息的调用者为同一个地址*/(campaign/*结构体的实例campaign可以拥有该结构体的属性，用campaig.来表达*/.creator/*地址类型*//*这个众筹id的创建者地址*/==msg.sender/*地址类型*//*这条消息的发送者*/, unicode"对不起，你不是众筹合约的创建者 not creator");
        require/*要求当前区块时间戳小于这次众筹活动开始的时间*/(block.timestamp/*uint类型*//*当前区块时间戳*/< campaign/*结构体的实例campaign可以拥有该结构体的属性，用campaig.来表达*/.startAt/*uint*//*众筹开始时间*/, unicode"众筹已经开始了，无法取消本次众筹 started");

        delete/*将众筹的映射id对应的值删除*/ campaigns/*结构体类型*//*Campaign结构体的实例*/[_id/*uint*//*众筹活动的id*/];
        emit Cancel/*事件类型*/(_id)/*uint*//*众筹活动的id*/;
    }

    function pledge/*函数名*//*参与众筹*/(uint _id/*uint*//*众筹活动的id*/, uint _amount/*uint*//*这次众筹的新参与进来的token数量*/) external {
        Campaign storage/*要修改掉参与众筹结构体的一些变量值，所以要将众筹结构体装到storage存储中，然后就可以修改它的变量值了*/ campaign/*结构体的实例campaign可以拥有该结构体的属性，用campaig.来表达*/= campaigns/*结构体类型*//*Campaign结构体的实例*/[_id/*uint*//*众筹活动的id*/];
        require/*判断众筹活动有没有开始*/(block.timestamp/*uint类型*//*当前区块时间戳*/>= campaign/*结构体的实例campaign可以拥有该结构体的属性，用campaig.来表达*/.startAt/*uint*//*众筹开始时间*/, unicode"众筹还没有开始not started");
        require/*判断众筹活动有没有结束*/(block.timestamp/*uint类型*//*当前区块时间戳*/<= campaign/*结构体的实例campaign可以拥有该结构体的属性，用campaig.来表达*/.endAt/*uint*//*众筹结束时间*/,  unicode"众筹已经结束ended");

        campaign/*结构体的实例campaign可以拥有该结构体的属性，用campaig.来表达*/.pledged/*uint*//*这次众筹的token数量参与进来*/+= _amount/*uint*//*这次众筹的新参与进来的token数量*/;//总的参与众筹的数量
        pledgedAmount/*映射类型*//*承诺的数量*/[_id]/*uint*//*众筹活动的id*/[msg.sender]/*地址类型*//*这条消息的发送者*//*当前用户地址*/+= _amount/*uint*//*这次众筹的新参与进来的token数量*/;//给这个参与指定id号众筹的用户它的token总数量也要加上_amount数量。因为一个用户有可能重复参与一个众筹
        token/*地址类型*//*IERC20接口合约地址*//*token作为IERC20接口合约的地址类型，具有使用该接口合约的函数方法tranferFrom*/.transferFrom/*IERC20的标准方法之一的transferFrom方法*/(msg.sender/*地址类型*//*这条消息的发送者*//*当前用户地址*/, address(this)/*地址类型*//*当前合约的地址*/, _amount/*uint*//*这次众筹的新参与进来的token数量*/);

        emit Pledge(_id/*uint*//*众筹活动的id*/,msg.sender/*地址类型*//*这条消息的发送者*//*当前用户地址*/, _amount/*uint*//*这次众筹的新参与进来的token数量*/);
    }

    function unpledge/*函数名*//*取消参与众筹*//*代表一个众筹活动在没有结束之前，用户是可以反悔的*/(uint _id/*uint*//*众筹活动的id*/, uint _amount/*uint*//*这次众筹的用户反悔减少的token数量*/) external {
        Campaign storage/*要修改掉参与众筹结构体的一些变量值，所以要将众筹结构体装到storage存储中，然后就可以修改它的变量值了*/ campaign/*结构体的实例campaign可以拥有该结构体的属性，用campaig.来表达*/= campaigns/*结构体类型*//*Campaign结构体的实例*/[_id/*uint*//*众筹活动的id*/];
        require/*判断众筹活动有没有结束，如果结束了，就不能取消*/(block.timestamp/*uint类型*//*当前区块时间戳*/<= campaign/*结构体的实例campaign可以拥有该结构体的属性，用campaig.来表达*/.endAt/*uint*//*众筹结束时间*/, unicode"抱歉，众筹活动已经结束了ended");

        campaign/*结构体的实例campaign可以拥有该结构体的属性，用campaig.来表达*/.pledged/*uint*//*这次众筹的token数量参与进来*/-= _amount/*uint*//*这次众筹的用户反悔减少的token数量*/;//总参与众筹的token数量减去这个用户反悔的数量
        pledgedAmount/*映射类型*//*承诺的数量*/[_id]/*uint*//*众筹活动的id*/[msg.sender]/*地址类型*//*这条消息的发送者*//*当前用户地址*/-= _amount/*uint*//*这次众筹的用户反悔减少的token数量*/;
        token/*地址类型*//*IERC20接口合约地址*//*token作为IERC20接口合约的地址类型，具有使用该接口合约的函数方法tranfer*/.transfer/*IERC20的标准方法之一的transfer方法*//*不要用transferFrom方法了，因为这次发送是由合约地址直接发送给消息调用者msg.sender,，所以用transfer就可以了*/(msg.sender/*地址类型*//*这条消息的发送者*//*当前用户地址*/, _amount/*uint*//*这次众筹的用户反悔减少的token数量*/);

        emit Unpledge/*事件类型*//*这个事件代表有用户撤销众筹了*/(_id/*uint*//*众筹活动的id*/, msg.sender/*地址类型*//*这条消息的发送者*//*当前用户地址*/, _amount/*uint*//*这次众筹的用户反悔减少的token数量*/);
    }

    function claim/*函数名*//*众筹创建者在达到众筹目标后将众筹的token取出来*/(uint _id)/*uint*//*众筹活动的id*/ external {
        Campaign storage/*要修改掉参与众筹结构体的一些变量值，所以要将众筹结构体装到storage存储中，然后就可以修改它的变量值了*/ campaign/*结构体的实例campaign可以拥有该结构体的属性，用campaig.来表达*/= campaigns/*结构体类型*//*Campaign结构体的实例*/[_id/*uint*//*众筹活动的id*/];
        require/*要求众筹合约的创建着和当前消息调用者一致*/(campaign/*结构体的实例campaign可以拥有该结构体的属性，用campaig.来表达*/.creator/*地址类型*//*众筹的创建者地址*/== msg.sender/*地址类型*//*这条消息的发送者*//*当前用户地址*/,unicode"对不起，你不是本次众筹合约的创建者not creator");
        require/*要求当前区块时间戳大于众筹结束时间，也就是要求众筹已经结束*/(block.timestamp/*uint类型*//*当前区块时间戳*/>campaign/*结构体的实例campaign可以拥有该结构体的属性，用campaig.来表达*/.endAt/*uint*//*众筹结束时间*/, unicode"对不起，本次众筹活动还未结束not ended");
        require/*要求众筹的实际token数量大于等于众筹目标token数量*/(campaign/*结构体的实例campaign可以拥有该结构体的属性，用campaig.来表达*/.pledged/*uint*//*这次众筹的token数量参与进来*/>= campaign/*结构体的实例campaign可以拥有该结构体的属性，用campaig.来表达*/.goal/*uint*//*众筹的token数量目标*/, unicode"众筹到的token总量小于众筹token数量目标pledged < goal");
        require/*要求众筹合约里众筹的token还没有被众筹合约创建者领取过*/(!campaign/*结构体的实例campaign可以拥有该结构体的属性，用campaig.来表达*/.claimed/*bool类型*//*众筹的token是否已被领取*//*true状态表示众筹的token已经被创建者领走*//*false状态表示众筹的token没有被创建者领走*/, unicode"对不起，众筹token已经被合约创建者领取过了claimed");

        campaign/*结构体的实例campaign可以拥有该结构体的属性，用campaig.来表达*/.claimed/*bool类型*//*众筹的token是否已被领取*//*true状态表示众筹的token已经被创建者领走*//*false状态表示众筹的token没有被创建者领走*/= true/*这里设置为true后，下次这个众筹合约的claim函数就不能被调用了，一个众筹合约只能有一次claim*/;
        token/*地址类型*//*IERC20接口合约地址*//*token作为IERC20接口合约的地址类型，具有使用该接口合约的函数方法tranfer*/.transfer/*IERC20的标准方法之一的transfer方法*//*不要用transferFrom方法了，因为这次发送是由合约地址直接发送给消息调用者msg.sender,，所以用transfer就可以了*/(campaign/*结构体的实例campaign可以拥有该结构体的属性，用campaig.来表达*/.creator/*地址类型*//*众筹的创建者地址*/, campaign/*结构体的实例campaign可以拥有该结构体的属性，用campaig.来表达*/.pledged/*uint*//*这次众筹的token数量参与进来*/);//这里campaign.creator == msg.sender，使用结构体中的creator会更加浪费gas，msg.sender在内存中就不浪费gas了

        emit Claim/*事件类型*//*这个事件代表众筹的token已被领取了*/(_id/*uint*//*众筹活动的id*/);
    }

    function refund/*函数名*//*众筹没有达到目标参与众筹者可以将之前参与众筹的token取出来*/(uint _id/*uint*//*众筹活动的id*/) external {
        Campaign memory campaign/*结构体的实例campaign可以拥有该结构体的属性，用campaig.来表达*/= campaigns/*结构体类型*//*Campaign结构体的实例*/[_id/*uint*//*众筹活动的id*/];
        require/*要求当前区块时间戳大于众筹结束时间，也就是要求众筹已经结束*/(block.timestamp/*uint类型*//*当前区块时间戳*/> campaign/*结构体的实例campaign可以拥有该结构体的属性，用campaig.来表达*/.endAt/*uint*//*众筹结束时间*/, "not ended");
        require/*要求众筹的实际token数量小于众筹目标token数量*/(campaign/*结构体的实例campaign可以拥有该结构体的属性，用campaig.来表达*/.pledged/*uint*//*这次众筹的token数量参与进来*/< campaign/*结构体的实例campaign可以拥有该结构体的属性，用campaig.来表达*/.goal/*uint*//*众筹的token数量目标*/, "pledged >= goal");

        uint bal/*uint*//*当前用户在某一个众筹id活动之下的参与众筹的总的token数量*/=pledgedAmount/*映射类型*//*承诺的数量*/[_id/*uint*//*众筹活动的id*/][msg.sender/*地址类型*//*这条消息的发送者*//*当前用户地址*/];
        pledgedAmount/*映射类型*//*承诺的数量*/[_id/*uint*//*众筹活动的id*/][msg.sender/*地址类型*//*这条消息的发送者*//*当前用户地址*/] = 0/*把这个映射中的数量清零，代表着当前用户地址只能取回一次，否则容易造成用户重复领取，容易出漏洞bug*/;
        token/*地址类型*//*IERC20接口合约地址*//*token作为IERC20接口合约的地址类型，具有使用该接口合约的函数方法tranfer*/.transfer/*IERC20的标准方法之一的transfer方法*//*不要用transferFrom方法了，因为这次发送是由合约地址直接发送给消息调用者msg.sender,，所以用transfer就可以了*/(msg.sender/*地址类型*//*这条消息的发送者*//*当前用户地址*/, bal/*uint*//*当前用户在某一个众筹id活动之下的参与众筹的总的token数量*/);//通过IERC20的方法将当前合约的token发送到当前用户地址上

        emit Refund/*事件类型*//*代表用户取回了参与众筹的token数量*/(_id/*uint*//*众筹活动的id*/, msg.sender/*地址类型*//*这条消息的发送者*//*当前用户地址*/, bal/*uint*//*当前用户在某一个众筹id活动之下的参与众筹的总的token数量*/);
    }
}