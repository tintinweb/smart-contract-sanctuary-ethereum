# @version ^0.3.7

event NewTweet:
    pk: uint128
    sender: indexed(address)
    text: String[300]
    display_name: indexed(String[40])
    hashtag: indexed(String[30])
    retweet_of: uint128
    is_reply_retweet: bool

event NewReply:
    pk: uint128
    sender: indexed(address)
    text: String[600]
    display_name: indexed(String[40])
    tweet: indexed(uint128)
    seq_num: uint16

event NewLike:
    pk: indexed(uint128)
    sender: address

event NewReplyLike:
    pk: indexed(uint128)
    sender: address

struct Tweet:
    pk: uint128
    sender: address
    text: String[300]
    display_name: String[40]
    hashtag: String[30]
    likes: uint32
    retweets: uint32
    retweet_of: uint128
    is_reply_retweet: bool

struct Reply:
    pk: uint128
    sender: address
    text: String[600]
    display_name: String[40]
    tweet: uint128
    seq_num: uint16
    likes: uint32
    retweets: uint32

num_tweets: public(uint128)
tweets: public(HashMap[uint128, Tweet])
num_tweets_per_sender: public(HashMap[address, uint64])
tweets_per_sender: public(HashMap[address, HashMap[uint64, uint128]])

num_tweets_per_hashtag: public(HashMap[String[30], uint64])
tweets_per_hashtag: public(HashMap[String[30], HashMap[uint64, uint128]])

@internal
def tweet_internal(
    text: String[300], display_name: String[40], hashtag: String[30], retweet_of: uint128, is_reply_retweet: bool
) -> uint128:
    prev: Tweet = self.tweets[self.tweets_per_sender[msg.sender][self.num_tweets_per_sender[msg.sender]]]
    if prev.text == text and prev.display_name == display_name:
        raise "duplicate tweet"

    self.num_tweets += 1
    self.num_tweets_per_sender[msg.sender] += 1

    self.tweets[self.num_tweets] = Tweet({
        pk: self.num_tweets,
        sender: msg.sender,
        text: text,
        display_name: display_name,
        hashtag:hashtag,
        likes: 0,
        retweets: 0,
        retweet_of: retweet_of,
        is_reply_retweet: is_reply_retweet,
    })

    self.tweets_per_sender[msg.sender][self.num_tweets_per_sender[msg.sender]] = self.num_tweets

    if hashtag != "":
        self.num_tweets_per_hashtag[hashtag] += 1
        self.tweets_per_hashtag[hashtag][self.num_tweets_per_hashtag[hashtag]] = self.num_tweets

    log NewTweet(self.num_tweets, msg.sender, text, display_name, hashtag, retweet_of, is_reply_retweet)

    return self.num_tweets

@external
def tweet(
    text: String[300], display_name: String[40], hashtag: String[30]
) -> uint128:
    return self.tweet_internal(text, display_name, hashtag, 0, False)

@external
def retweet(
    pk: uint128, text: String[300], display_name: String[40]
) -> uint128:
    if pk > self.num_tweets or pk == 0:
        raise "retweeting a non-existing tweet"

    self.tweets[pk].retweets += 1
    return self.tweet_internal(text, display_name, self.tweets[pk].hashtag, pk, False)

@external
def retweet_reply(
    pk: uint128, text: String[300], display_name: String[40]
) -> uint128:
    if pk > self.num_replies or pk == 0:
        raise "retweeting a non-existing reply"

    self.replies[pk].retweets += 1
    return self.tweet_internal(text, display_name, self.tweets[self.replies[pk].tweet].hashtag, pk, True)

num_replies: public(uint128)
replies: public(HashMap[uint128, Reply])
num_replies_per_tweet: public(HashMap[uint128, uint16])
replies_per_tweet: public(HashMap[uint128, HashMap[uint16, uint128]])

@external
def reply(
    text: String[600], display_name: String[40], tweet: uint128, seq_num: uint16
) -> uint128:
    if tweet > self.num_tweets or tweet == 0:
        raise "replying to a non-existing tweet"

    prev: Reply = self.replies[self.replies_per_tweet[tweet][self.num_replies_per_tweet[tweet]]]
    if  prev.text == text and prev.display_name == prev.display_name:
        raise "duplicate reply"

    self.num_replies += 1
    self.num_replies_per_tweet[tweet] += 1

    self.replies[self.num_replies] = Reply({
        pk: self.num_replies,
        sender: msg.sender,
        text: text,
        display_name: display_name,
        tweet: tweet,
        seq_num: seq_num,
        likes: 0,
        retweets: 0,
    })

    self.replies_per_tweet[tweet][self.num_replies_per_tweet[tweet]] = self.num_replies

    log NewReply(self.num_replies, msg.sender, text, display_name, tweet, seq_num)

    return self.num_replies

@external
def like(pk: uint128):
    self.tweets[pk].likes += 1
    log NewLike(pk, msg.sender)

@external
def like_reply(pk: uint128):
    self.replies[pk].likes += 1
    log NewReplyLike(pk, msg.sender)