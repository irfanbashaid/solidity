pragma solidity ^0.4.21;
import "./High_low_3_token.sol";

contract High_low_3
{
    High_low_3_token token;
    
    address public admin;
    
    constructor(High_low_3_token _token) public payable
    {
        admin = msg.sender;
        token = _token;
    }
    
    event Transfer_amount(address _sender, address _receiver, uint256 _transfer_amount);
    
    function token_transaction(uint256 tokens_to_exchange_in_wei) public payable returns(bool) //retun: if it return "true: tokens boughted successfully" "false: tokens not boughted"
    {
        require(tokens_to_exchange_in_wei>0 || msg.value>0);
        if(tokens_to_exchange_in_wei != 0)
        {
            High_low_3_token(token).transferFrom(msg.sender, token, tokens_to_exchange_in_wei);
            msg.sender.transfer(tokens_to_exchange_in_wei/1000);
            emit Transfer_amount(this, msg.sender, tokens_to_exchange_in_wei/1000);
            return true;
        }
        else if(msg.value != 0)
        {
            High_low_3_token(token).transferFrom(token,msg.sender, msg.value*1000); //To sell 1 token for 0.001 ether
            emit Transfer_amount(msg.sender, this, msg.value);
            return true;
        }
    }
    
    uint256 public game_id;  //it is unique game id
    
    struct  broker
    {
        uint256 stake_amount;
        uint256 stake_token;
        bool is_broker;
        uint256 active_offerings;
        uint256[] broker_bets;  
    }
    mapping(address=>broker) public broker_map;
    
    function add_broker() public payable returns (bool) // is_added
    {
        require(broker_map[msg.sender].is_broker==false);
        broker_map[msg.sender].is_broker=true;
        return true;
    }
    
    function add_stake(uint256 token_to_stake) public payable returns(bool)
    {
        require(msg.value>0 || token_to_stake > 0);
        if(token_to_stake!=0)
        {
            High_low_3_token(token).transferFrom(msg.sender, token, token_to_stake);
            broker_map[msg.sender].stake_token += token_to_stake;
            return true;
        }
        else 
        {
            broker_map[msg.sender].stake_amount += msg.value;
            emit Transfer_amount(msg.sender,this,msg.value);
            return true;
        }
    }
    
    function broker_withdraw_from_stake(bool _what, uint256 amount_to_withdraw) public payable returns(bool) // is_de_registered  false: ether true: token
    {
        require(amount_to_withdraw>0);
        if(!_what)
        {
            require(broker_map[msg.sender].stake_amount >=  amount_to_withdraw);
            msg.sender.transfer(amount_to_withdraw);
            broker_map[msg.sender].stake_amount -= amount_to_withdraw;
            emit Transfer_amount(this, msg.sender, amount_to_withdraw);
            return true;
        }
        else 
        {
            require(broker_map[msg.sender].stake_token >= amount_to_withdraw);
            High_low_3_token(token).transferFrom(token, msg.sender, amount_to_withdraw);
            broker_map[msg.sender].stake_token -= amount_to_withdraw;
            return true;
        }
    }

    function broker_de_registration() public payable returns(bool) // is_de_registered
    {
        require(broker_map[msg.sender].active_offerings == 0);
        msg.sender.transfer(broker_map[msg.sender].stake_amount);
        broker_map[msg.sender].stake_amount = 0;
        High_low_3_token(token).transferFrom(token, msg.sender, broker_map[msg.sender].stake_token);
        broker_map[msg.sender].stake_token = 0; 
        emit Transfer_amount(admin,msg.sender,broker_map[msg.sender].stake_amount);
        broker_map[msg.sender].is_broker=false;
        return true;
    }
    
    struct game_set
    {
        string stock_name;
        uint256 strike_price;
        uint256 expiry_time;
        address bet_creator;
        address[] betters_of_bet; 
        uint256 total_bet_amount; 
        uint256 total_bet_tokens; 
        uint256 result_map; 
    }
    mapping(uint256=>game_set) public game_set_map;//key:bet_id   

    // mapping(address=>uint256[]) public broker_bets; //broker created bets
    
    // mapping(uint256=>address) public bet_creator; //address of bet creator address  
    
    function broker_set_game(string _stock_name,uint256 _strike_price,uint256 _expiry_time) public payable returns(bool) // newbet created
    {
        require(_expiry_time>now);
        game_set_map[game_id].stock_name=_stock_name;
        game_set_map[game_id].strike_price=_strike_price;
        game_set_map[game_id].expiry_time=_expiry_time;
        broker_map[msg.sender].broker_bets.push(game_id);
        game_set_map[game_id].bet_creator = msg.sender;
        broker_map[msg.sender].active_offerings++;
        game_id++;
        return true;
    }
    
    struct better
    {
        bool option;
        uint256 bet_amount; 
        uint256 betted_tokens;
        bool is_exit; 
    }
    mapping(address=>mapping(uint256=>better)) public betting_map; //key1:User address key2:bet id
    
    // mapping(uint256=>address[]) public betters_of_bet; //key: bet_id
    
    // mapping(address=>uint256[]) public user_bets; // key: user address value: bet_id
    
    // mapping(address=>mapping(uint256=>bool)) public is_exit; //key1: user_address key2: bet_id     
    
    // mapping(uint256=>uint256) public total_bet_amount; //key: gameid  value:total bet amount of that particular bet
    
    // mapping(uint256=>uint256) public total_bet_tokens; //key: gameid  value:total bet amount of that particular bet
    
    // mapping(uint256=>uint256) public result_map;//to check is_result_published  10 -> low  11 -> high  12 -> draw
    
    function betting(uint256 _game_id,uint256 _choice,uint256 _bet_tokens) public payable returns(bool) // is_bet_success 
    {
        require(game_set_map[_game_id].expiry_time - 1 minutes > now);
        require(_bet_tokens>0 || msg.value>0);
        require(betting_map[msg.sender][_game_id].is_exit==false);
        require(betting_map[msg.sender][_game_id].bet_amount == 0);
        require(betting_map[msg.sender][_game_id].betted_tokens == 0);
        require(broker_map[game_set_map[game_id].bet_creator].stake_amount+(broker_map[game_set_map[game_id].bet_creator].stake_token/1000) >= ((msg.value + (_bet_tokens/1000))*90)/100);
        require(_choice==1||_choice==0);
        
        if(_bet_tokens > 0) //for token bet
        {
            bet(_game_id, _bet_tokens);
        }
        
        else if(msg.value != 0)  //for ether bet
        {
            bet(_game_id, 0);
        }
        
        if(_choice==1)
        {
            betting_map[msg.sender][_game_id].option=true;  //by default it is false
        }
        
        game_set_map[_game_id].betters_of_bet.push(msg.sender);
        // betters_of_bet[_game_id].push(msg.sender);
        // user_bets[msg.sender].push(_game_id);
        
        return true;
    }
    
    function bet(uint256 _game_id, uint256 _bet_tokens) public payable returns(bool)
    {
        address _bet_creator = game_set_map[game_id].bet_creator;
        if(_bet_tokens>0)
        {
            High_low_3_token(token).transferFrom(msg.sender, token, _bet_tokens);
            betting_map[msg.sender][_game_id].betted_tokens += _bet_tokens;
            game_set_map[_game_id].total_bet_tokens += _bet_tokens;
            
            if(broker_map[_bet_creator].stake_token >= (_bet_tokens*90)/100)
            {
                broker_map[_bet_creator].stake_token -= (_bet_tokens*90)/100;
            }
            else 
            {
                if(broker_map[_bet_creator].stake_token != 0)
                {
                    broker_map[_bet_creator].stake_amount -=  ((_bet_tokens*9)/10000 - (broker_map[_bet_creator].stake_token/1000));
                    broker_map[_bet_creator].stake_token=0;
                }
                else
                {
                    broker_map[_bet_creator].stake_amount -= (_bet_tokens*9)/10000;
                }
            }
            return true;
        }
        else
        {
            emit Transfer_amount(msg.sender,this,msg.value);
            betting_map[msg.sender][_game_id].bet_amount += msg.value;
            game_set_map[_game_id].total_bet_amount += msg.value;
            if(broker_map[_bet_creator].stake_amount >= (90*msg.value)/100)
            {
                broker_map[_bet_creator].stake_amount -= (90*msg.value)/100;
            }
            else
            {
                if(broker_map[_bet_creator].stake_amount != 0)
                {
                    broker_map[_bet_creator].stake_token -= ((msg.value*900) - (broker_map[_bet_creator].stake_amount*1000)); 
                    broker_map[_bet_creator].stake_amount = 0;
                }
                else
                {
                    broker_map[_bet_creator].stake_token -= (msg.value*900);
                }
            }   
        }
    }
   
    function trader_cancel_bet_and_widthdraw(uint256 _game_id) public payable returns(bool)// is_withdraw_success
    {
        require(betting_map[msg.sender][_game_id].is_exit==false);
        require(game_set_map[_game_id].expiry_time - 1 minutes > now);
        
        address _bet_creator = game_set_map[_game_id].bet_creator;
        uint256 how_much_;
        if(betting_map[msg.sender][_game_id].bet_amount != 0)
        {
            how_much_ = betting_map[msg.sender][_game_id].bet_amount;
            msg.sender.transfer((how_much_*95)/100);
            emit Transfer_amount(this, msg.sender, (how_much_*95)/100);
            broker_map[_bet_creator].stake_amount += (how_much_*95)/100;
            game_set_map[_game_id].total_bet_amount -= how_much_;
            betting_map[msg.sender][_game_id].bet_amount = 0;
        }
        
        if(betting_map[msg.sender][_game_id].betted_tokens != 0)
        {
            how_much_ = betting_map[msg.sender][_game_id].betted_tokens;
            High_low_3_token(token).transferFrom(token, msg.sender, (how_much_*95)/100);
            broker_map[_bet_creator].stake_token += (how_much_*95)/100;
            game_set_map[_game_id].total_bet_tokens -= how_much_;
            betting_map[msg.sender][_game_id].betted_tokens = 0;
        }
        
        betting_map[msg.sender][_game_id].is_exit=true;
        
        return true;
    }
    
    function increase(uint256 _game_id, uint256 _bet_tokens) public payable returns(bool)// is_increase_success
    {
        require(game_set_map[_game_id].expiry_time - 1 minutes > now);
        require(betting_map[msg.sender][_game_id].is_exit==false);
        require(broker_map[game_set_map[_game_id].bet_creator].stake_amount+(broker_map[game_set_map[_game_id].bet_creator].stake_token/1000) >= (msg.value*90)/100 + (_bet_tokens*9/10000));
        
        if(_bet_tokens > 0) //for token bet
        {
            bet(_game_id, _bet_tokens);
        }
        
        else if(msg.value != 0)  //for ether bet
        {
            bet(_game_id,0);
        }
        
        return true;
    }
    
    function decrease(uint256 _game_id, bool _what, uint256 _howmuch) public payable returns(bool)// is_increase_success
    {
        require(game_set_map[_game_id].expiry_time - 1 minutes > now);
        require(betting_map[msg.sender][_game_id].is_exit == false);
        require(_howmuch > 0);
        address _bet_creator = game_set_map[_game_id].bet_creator;
        if(_what == false)  //To decrease ether
        {
            require(betting_map[msg.sender][_game_id].bet_amount   >= _howmuch + 10000000000000000);  //0.01 ether
            msg.sender.transfer(_howmuch);
            betting_map[msg.sender][_game_id].bet_amount -= _howmuch;
            broker_map[_bet_creator].stake_amount += (_howmuch*90)/100;
            game_set_map[_game_id].total_bet_amount -= msg.value;
            emit Transfer_amount(this, msg.sender, _howmuch);
        }
        
        else if(_what == true) //To decrease Token
        {
            require(betting_map[msg.sender][_game_id].betted_tokens >= _howmuch + 10000000000000000000); //10 token
            High_low_3_token(token).transferFrom(token, msg.sender, _howmuch);
            betting_map[msg.sender][_game_id].betted_tokens -= _howmuch;
            broker_map[_bet_creator].stake_token += (_howmuch*90)/100;
            game_set_map[_game_id].total_bet_tokens -= _howmuch;
        }
        return true;
    }
    
    function admin_setting_result_and_distribute_money(uint256 _game_id,uint256 result_options) public payable returns(bool)// is_result_setted_and_prize_distributed 
    {
        require(admin==msg.sender);
        require(game_set_map[_game_id].expiry_time < now);
        require(game_set_map[_game_id].result_map == 0);
        require(result_options == 10 || result_options == 11 || result_options == 12);
        
        game_set_map[_game_id].result_map = result_options;
        
        game_set_map[_game_id].betters_of_bet.push(msg.sender);
        result_options = game_set_map[_game_id].betters_of_bet.length;
        
        address _bet_creator = game_set_map[_game_id].bet_creator;
        broker_map[_bet_creator].active_offerings--;
        
        address[] memory betters_of_bet_ = new address[](result_options);
        
        betters_of_bet_ = game_set_map[_game_id].betters_of_bet;
        
        uint256 _howmuch;
        
        if(game_set_map[_game_id].result_map == 11)
        {
            decider = true;
            
        }
        
        if(game_set_map[_game_id].result_map == 12)
        {
            //draw 
            while(result_options > 0)
            {
                result_options --;
                if(betting_map[betters_of_bet_[result_options]][_game_id].bet_amount != 0)
                {
                    _howmuch = betting_map[betters_of_bet_[result_options]][_game_id].bet_amount;
                    betters_of_bet_[result_options].transfer(_howmuch);
                    emit Transfer_amount(this, betters_of_bet_[result_options], _howmuch);//transfer amount to trader
                    broker_map[_bet_creator].stake_amount += _howmuch;
                }
                if(betting_map[betters_of_bet_[result_options]][_game_id].betted_tokens != 0)
                {
                    _howmuch = betting_map[betters_of_bet_[result_options]][_game_id].betted_tokens;
                    High_low_3_token(token).transferFrom(token, betters_of_bet_[result_options], _howmuch);
                    broker_map[_bet_creator].stake_token += _howmuch;
                }
            }
            
            return true;
        }
        
        else if(game_set_map[_game_id].result_map ==11 || game_set_map[_game_id].result_map == 10)
        {
            bool decider;
            if(game_set_map[_game_id].result_map ==11)
            {
                decider=true;
            }
            while(result_options>0)
            {
                result_options--;
                if(betting_map[betters_of_bet_[result_options]][_game_id].bet_amount != 0)
                {
                    _howmuch = betting_map[betters_of_bet_[result_options]][_game_id].bet_amount;
                    if(betting_map[betters_of_bet_[result_options]][_game_id].option == decider)  //user wins
                    {
                        betters_of_bet_[result_options].transfer((189*_howmuch)/100);
                        emit Transfer_amount(this, betters_of_bet_[result_options], (189*_howmuch)/100);//transfer amount to trader
                    }
                    else
                    {
                        broker_map[_bet_creator].stake_amount += (199*_howmuch)/100;
                    }
                }
                if(betting_map[betters_of_bet_[result_options]][_game_id].betted_tokens != 0)
                {
                    _howmuch = betting_map[betters_of_bet_[result_options]][_game_id].betted_tokens;
                    if(betting_map[betters_of_bet_[result_options]][_game_id].option == decider)
                    {
                        High_low_3_token(token).transferFrom(token, betters_of_bet_[result_options], (189*_howmuch)/100);
                    }
                    else 
                    {
                        broker_map[_bet_creator].stake_token += (199*_howmuch)/100;
                    }
                }
            }
          
            return true;
        }
    }
}
