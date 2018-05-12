pragma solidity ^0.4.0;
import "./High_low_3_token.sol";

contract High_low_3
{
    High_low_3_token token;
    
    address public admin;
    
    function High_low_3(High_low_3_token _token) public payable
    {
        admin = msg.sender;
        token = _token;
    }
    
    event Transfer_amount(address _sender, address _receiver, uint256 _transfer_amount);
    
    function buy_token() public payable returns(bool) //retun: if it return "true: tokens boughted successfully" "false: tokens not boughted"
    {
        High_low_3_token(token).transferFrom(token,msg.sender, msg.value*1000); //To sell 1 token for 0.001 ether
        Transfer_amount(msg.sender, this, msg.value);
        return true;
    }
    
    function exchange_token(uint256 tokens_to_exchange_in_wei) public payable returns(bool) //arg1: web3.toWei(no.of.token to convert , 'ether')  return: if it return "true: tokens successfully exchanged" "false: tokens not exchanged"
    {
        High_low_3_token(token).transferFrom(msg.sender, token, tokens_to_exchange_in_wei);
        msg.sender.transfer(tokens_to_exchange_in_wei/1000);
        Transfer_amount(this, msg.sender, tokens_to_exchange_in_wei/1000);
        return true;
    }
    
    uint256 public game_id;  //it is unique game id
    
    struct  broker
    {
        uint256 stake_amount;
        uint256 stake_token;
    }
    mapping(address=>broker) public broker_map;
    
    mapping(address=>bool) public is_broker;
    
    function add_broker() public payable returns (bool) // is_added
    {
        require(is_broker[msg.sender]==false);
        is_broker[msg.sender]=true;
        return true;
    }
    
    function add_stake_token(uint256 token_to_stake) public payable returns(bool)
    {
        High_low_3_token(token).transferFrom(msg.sender, token, token_to_stake);
        broker_map[msg.sender].stake_token += token_to_stake; 
        return true;
    }
    
    function add_stake_amount() public payable returns(bool) //amount_added 
    {
        require(msg.value>0);
        broker_map[msg.sender].stake_amount += msg.value;
        Transfer_amount(msg.sender,this,msg.value);
        return true;
    }
    
    function broker_withdraw_amount_from_stake(uint256 amount_to_withdraw) public payable returns(bool) // is_de_registered
    {
        require(amount_to_withdraw > 0 && broker_map[msg.sender].stake_amount >=  amount_to_withdraw);
        msg.sender.transfer(amount_to_withdraw);
        broker_map[msg.sender].stake_amount -= amount_to_withdraw;
        Transfer_amount(this, msg.sender, amount_to_withdraw);
        return true;
    }
    
    function broker_withdraw_token_from_stake(uint256 token_to_withdraw) public payable returns(bool) // is_de_registered
    {
        require(token_to_withdraw>0 && broker_map[msg.sender].stake_token >= token_to_withdraw);
        High_low_3_token(token).transferFrom(token, msg.sender, token_to_withdraw);
        broker_map[msg.sender].stake_token -= token_to_withdraw;
        return true;
    }
    
    mapping(address=>uint256) public active_offerings;
    
    function broker_de_registration() public payable returns(bool) // is_de_registered
    {
        require(active_offerings[msg.sender] == 0);
        if(broker_map[msg.sender].stake_amount != 0)
        {
            msg.sender.transfer(broker_map[msg.sender].stake_amount);
            broker_map[msg.sender].stake_amount = 0;
            Transfer_amount(this, msg.sender, broker_map[msg.sender].stake_amount);
        }
        else if(broker_map[msg.sender].stake_token != 0)
        {
            High_low_3_token(token).transferFrom(token, msg.sender, broker_map[msg.sender].stake_token);
            broker_map[msg.sender].stake_token = 0; 
        }
        is_broker[msg.sender]=false;
        return true;
    }
    
    struct game_set
    {
        string stock_name;
        uint256 strike_price;
        uint256 expiry_time;
    }
    mapping(uint256=>game_set) public game_set_map;//key:bet_id   

    mapping(address=>uint256[]) public broker_bets; //broker created bets
    
    mapping(uint256=>address) public bet_creator; //address of bet creator address  
    
    function broker_set_game(string _stock_name,uint256 _strike_price,uint256 _expiry_time) public payable returns(bool) // newbet created
    {
        require(_expiry_time>now);
        game_set_map[game_id].stock_name=_stock_name;
        game_set_map[game_id].strike_price=_strike_price;
        game_set_map[game_id].expiry_time=_expiry_time;
        broker_bets[msg.sender].push(game_id);
        bet_creator[game_id]=msg.sender;
        active_offerings[msg.sender]++;
        game_id++;
        return true;
    }
    
    struct better
    {
        bool option;
        uint256 bet_amount; 
        uint256 betted_tokens; 
    }
    mapping(address=>mapping(uint256=>better)) public betting_map; //key1:User address key2:bet id
    
    mapping(uint256=>address[]) public betters_of_bet; //key: bet_id
    
    mapping(address=>uint256[]) public user_bets; // key: user address value: bet_id
    
    mapping(address=>mapping(uint256=>bool)) public is_exit; //key1: user_address key2: bet_id     
    
    mapping(uint256=>uint256) public total_bet_amount; //key: gameid  value:total bet amount of that particular bet
    
    mapping(uint256=>uint256) public total_bet_tokens; //key: gameid  value:total bet amount of that particular bet
    
    function betting(uint256 _game_id,uint256 _choice,uint256 _bet_tokens) public payable returns(bool) // is_bet_success 
    {
        require(game_set_map[_game_id].expiry_time - 1 minutes > now);
        require(_bet_tokens>0 || msg.value>0);
        require(is_exit[msg.sender][_game_id]==false);
        require(betting_map[msg.sender][_game_id].bet_amount == 0);
        require(betting_map[msg.sender][_game_id].betted_tokens == 0);
        require(broker_map[bet_creator[_game_id]].stake_amount+(broker_map[bet_creator[_game_id]].stake_token/1000) >= ((msg.value + (_bet_tokens/1000))*90)/100);
        require(_choice==1||_choice==0);
        
        if(_bet_tokens > 0) //for token bet
        {
            token_bet(_game_id, _bet_tokens);
        }
        
        else if(msg.value != 0)  //for ether bet
        {
            ether_bet(_game_id);
        }
        
        if(_choice==1)
        {
            betting_map[msg.sender][_game_id].option=true;  //by default it is false
        }
        
        betters_of_bet[_game_id].push(msg.sender);
        user_bets[msg.sender].push(_game_id);
        
        return true;
    }
    
    function ether_bet(uint256 _game_id) public payable returns(bool)
    {
        Transfer_amount(msg.sender,this,msg.value);
        betting_map[msg.sender][_game_id].bet_amount += msg.value;
        total_bet_amount[_game_id] += msg.value;
        if(broker_map[bet_creator[_game_id]].stake_amount >= (90*msg.value)/100)
        {
            broker_map[bet_creator[_game_id]].stake_amount -= (90*msg.value)/100;
        }
        else
        {
            if(broker_map[bet_creator[_game_id]].stake_amount != 0)
            {
                broker_map[bet_creator[_game_id]].stake_token -= ((msg.value*900) - (broker_map[bet_creator[_game_id]].stake_amount*1000)); 
                broker_map[bet_creator[_game_id]].stake_amount = 0;
            }
            else
            {
                broker_map[bet_creator[_game_id]].stake_token -= (msg.value*900);
            }
        }        
    }
    
    function token_bet(uint256 _game_id, uint256 _bet_tokens) public payable returns(bool)
    {
        High_low_3_token(token).transferFrom(msg.sender, token, _bet_tokens);
        betting_map[msg.sender][_game_id].betted_tokens += _bet_tokens;
        total_bet_tokens[_game_id] += _bet_tokens;
        if(broker_map[bet_creator[_game_id]].stake_token >= (_bet_tokens*90)/100)
        {
            broker_map[bet_creator[_game_id]].stake_token -= (_bet_tokens*90)/100;
        }
        else 
        {
            if(broker_map[bet_creator[_game_id]].stake_token != 0)
            {
                broker_map[bet_creator[_game_id]].stake_amount -=  ((_bet_tokens*9)/10000 - (broker_map[bet_creator[_game_id]].stake_token/1000));
                broker_map[bet_creator[_game_id]].stake_token=0;
            }
            else
            {
                broker_map[bet_creator[_game_id]].stake_amount -= (_bet_tokens*9)/10000;
            }
        }
    }
    
    function trader_cancel_bet_and_widthdraw(uint256 _game_id) public payable returns(bool)// is_withdraw_success
    {
        require(is_exit[msg.sender][_game_id]==false);
        require(game_set_map[_game_id].expiry_time - 1 minutes > now);
        
        if(betting_map[msg.sender][_game_id].bet_amount != 0)
        {
            msg.sender.transfer((betting_map[msg.sender][_game_id].bet_amount*95)/100);
            Transfer_amount(this, msg.sender, (betting_map[msg.sender][_game_id].bet_amount*95)/100);
            broker_map[bet_creator[_game_id]].stake_amount += (betting_map[msg.sender][_game_id].bet_amount*95)/100;
            total_bet_amount[_game_id] -= betting_map[msg.sender][_game_id].bet_amount;
            betting_map[msg.sender][_game_id].bet_amount = 0;
        }
        
        if(betting_map[msg.sender][_game_id].betted_tokens != 0)
        {
            High_low_3_token(token).transferFrom(token, msg.sender, (betting_map[msg.sender][_game_id].betted_tokens*95)/100);
            broker_map[bet_creator[_game_id]].stake_token += (betting_map[msg.sender][_game_id].betted_tokens*95)/100;
            total_bet_tokens[_game_id] -= betting_map[msg.sender][_game_id].betted_tokens;
            betting_map[msg.sender][_game_id].betted_tokens = 0;
        }
        
        is_exit[msg.sender][_game_id]=true;
        
        return true;
    }
    
    function increase(uint256 _game_id, uint256 _bet_tokens) public payable returns(bool)// is_increase_success
    {
        require(game_set_map[_game_id].expiry_time - 1 minutes > now);
        require(is_exit[msg.sender][_game_id]==false);
        require(broker_map[bet_creator[_game_id]].stake_amount+(broker_map[bet_creator[_game_id]].stake_token/1000) >= (msg.value*90)/100 + (_bet_tokens*9/10000));
        
        if(_bet_tokens > 0) //for token bet
        {
            token_bet(_game_id, _bet_tokens);
        }
        
        else if(msg.value != 0)  //for ether bet
        {
            ether_bet(_game_id);
        }
        
        return true;
    }
    
    function decrease(uint256 _game_id, bool _what, uint256 _howmuch) public payable returns(bool)// is_increase_success
    {
        require(game_set_map[_game_id].expiry_time - 1 minutes > now);
        require(is_exit[msg.sender][_game_id]==false);
        require(_howmuch > 0);
        if(_what == false)  //To decrease ether
        {
            require(betting_map[msg.sender][_game_id].bet_amount >= _howmuch + 10000000000000000);  //0.01 ether
            msg.sender.transfer(_howmuch);
            betting_map[msg.sender][_game_id].bet_amount -= _howmuch;
            broker_map[bet_creator[_game_id]].stake_amount += (_howmuch*90)/100;
            total_bet_amount[_game_id] -= msg.value;
            Transfer_amount(this, msg.sender, _howmuch);
        }
        
        else if(_what == true) //To decrease Token
        {
            require(betting_map[msg.sender][_game_id].betted_tokens >= _howmuch + 10000000000000000000); //10 token
            High_low_3_token(token).transferFrom(token, msg.sender, _howmuch);
            betting_map[msg.sender][_game_id].betted_tokens -= _howmuch;
            broker_map[bet_creator[_game_id]].stake_token += (_howmuch*90)/100;
            total_bet_tokens[_game_id] -= _howmuch;
        }
        return true;
    }
    
    mapping(uint256=>uint256) public result_map;//to check is_result_published  10 -> low  11 -> high  12 -> draw
    
    function admin_setting_result_and_distribute_money(uint256 _game_id,uint256 result_options) public payable returns(bool)// is_result_setted_and_prize_distributed 
    {
        require(admin==msg.sender);
        require(game_set_map[_game_id].expiry_time < now);
        require(result_map[_game_id] == 0);
        require(result_options==10 || result_options==11 ||result_options==12);
        
        result_map[_game_id] = result_options;
        result_options = betters_of_bet[_game_id].length;
        active_offerings[bet_creator[_game_id]]--;
        
        if(result_map[_game_id] == 12)
        {
            //draw 
            while(result_options > 0)
            {
                result_options --;
                if(betting_map[betters_of_bet[_game_id][result_options]][_game_id].bet_amount != 0)
                {
                    betters_of_bet[_game_id][result_options].transfer(betting_map[betters_of_bet[_game_id][result_options]][_game_id].bet_amount);
                    Transfer_amount(this, betters_of_bet[_game_id][result_options], betting_map[betters_of_bet[_game_id][result_options]][_game_id].bet_amount);//transfer amount to trader
                    broker_map[bet_creator[_game_id]].stake_amount += betting_map[betters_of_bet[_game_id][result_options]][_game_id].bet_amount;
                }
                else if(betting_map[betters_of_bet[_game_id][result_options]][_game_id].betted_tokens != 0)
                {
                    High_low_3_token(token).transferFrom(token, betters_of_bet[_game_id][result_options], betting_map[betters_of_bet[_game_id][result_options]][_game_id].betted_tokens);
                    broker_map[bet_creator[_game_id]].stake_token += betting_map[betters_of_bet[_game_id][result_options]][_game_id].betted_tokens;
                }
            }
            
            return true;
        }
        
        else if(result_map[_game_id] ==11 || result_map[_game_id] == 10)
        {
            bool decider;
            if(result_map[_game_id] ==11)
            {
                decider=true;
            }
            while(result_options>0)
            {
                result_options--;
                if(betting_map[betters_of_bet[_game_id][result_options]][_game_id].bet_amount != 0)
                {
                    if(betting_map[betters_of_bet[_game_id][result_options]][_game_id].option == decider)  //user wins
                    {
                        betters_of_bet[_game_id][result_options].transfer((189*betting_map[betters_of_bet[_game_id][result_options]][_game_id].bet_amount)/100);
                        Transfer_amount(this, betters_of_bet[_game_id][result_options], (189*betting_map[betters_of_bet[_game_id][result_options]][_game_id].bet_amount)/100);//transfer amount to trader
                    }
                    else
                    {
                        broker_map[bet_creator[_game_id]].stake_amount += (199*betting_map[betters_of_bet[_game_id][result_options]][_game_id].bet_amount)/100;
                    }
                }
                else if(betting_map[betters_of_bet[_game_id][result_options]][_game_id].betted_tokens != 0)
                {
                    if(betting_map[betters_of_bet[_game_id][result_options]][_game_id].option == decider)
                    {
                        High_low_3_token(token).transferFrom(token, betters_of_bet[_game_id][result_options], (189*betting_map[betters_of_bet[_game_id][result_options]][_game_id].betted_tokens)/100);
                    }
                    else 
                    {
                        broker_map[bet_creator[_game_id]].stake_token += (199*betting_map[betters_of_bet[_game_id][result_options]][_game_id].betted_tokens)/100;
                    }
                }
            }
            
            return true;
        }
    }
}
