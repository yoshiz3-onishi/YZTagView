// ------------------------------------------------------------------------------------------------
import UIKit

// ------------------------------------------------------------------------------------------------
public enum TagViewOptions
{
	case OuterMergine				( CGFloat )
	case InnerMergine				( CGFloat )
	case BackgroundColor			( UIColor )
	case AutoGlowHeight				( Bool )
	case Font						( UIFont )
	case TagBackgroundColor			( UIColor )
	case TagTextColor				( UIColor )
	case TagPrefix					( String )
	case AddButtonBackgroundColor	( UIColor )
	case AddButtonTextColor			( UIColor )
	case EnableEdit					( Bool )
}

// ------------------------------------------------------------------------------------------------
@objc public protocol TagViewDelegate
{
	optional func onDidEndEditing( sender: UIView )
}

// ------------------------------------------------------------------------------------------------
class TagView: UIView, UITextFieldDelegate
{
	var _scrollView					: UIScrollView!
	var _tagIndex					: Int		= 0
	var _tagFields					: [Int: UITextField]! = [:]
	var _tagFieldMaxX				: CGFloat	= 0.0
	var _tagFieldMinY				: CGFloat	= 0.0
	var _basePosition				: CGPoint!
	var _baseSize					: CGSize!
	var _addButton					: UIButton!
	var _outerMergine				: CGFloat	= 5.0
	var _innerMergine				: CGFloat	= 2.5
	var _autoGlowHeight				: Bool		= true
	var _font						: UIFont!
	var _tagBackgroundColor			: UIColor	= UIColor.whiteColor()
	var _tagTextColor				: UIColor	= UIColor.blackColor()
	var _tagPrefix					: String	= "#"
	var _addButtonBackgroundColor	: UIColor	= UIColor.whiteColor()
	var _ddButtonTextColor			: UIColor	= UIColor.blackColor()
	var _enableEdit					: Bool		= true
	weak var delegate				: TagViewDelegate?

	// --------------------------------------------------------------------------------------------
	required init( coder aDecoder: NSCoder )
	{
		super.init( coder: aDecoder )!
	}
	// --------------------------------------------------------------------------------------------
	override init( frame: CGRect )
	{
		super.init( frame: frame )
	}
	// --------------------------------------------------------------------------------------------
	convenience init( position: CGPoint, size: CGSize, options: [TagViewOptions]? = nil )
	{
		self.init( frame: CGRectMake( position.x, position.y, size.width, size.height ) )
		
		_basePosition = position
		_baseSize	  = size

		if let _options = options
		{
			for option in _options
			{
				switch option
				{
					case let .OuterMergine				( value ): _outerMergine = value
					case let .InnerMergine				( value ): _innerMergine = value
					case let .AutoGlowHeight			( value ): _autoGlowHeight = value
					case let .BackgroundColor			( value ): backgroundColor = value
					case let .Font						( value ): _font = value
					case let .TagBackgroundColor		( value ): _tagBackgroundColor = value
					case let .TagTextColor				( value ): _tagTextColor = value
					case let .TagPrefix					( value ): _tagPrefix = value
					case let .AddButtonBackgroundColor	( value ): _addButtonBackgroundColor = value
					case let .AddButtonTextColor		( value ): _ddButtonTextColor = value
					case let .EnableEdit				( value ): enableEdit = value
				}
			}
		}
		
		_scrollView							= UIScrollView( frame: frame )
		_scrollView.pagingEnabled			= false
		_scrollView.frame					= CGRectMake( 0, 0, frame.width, frame.height )
		_scrollView.contentSize				= CGSizeMake( frame.width, frame.height )
		_scrollView.layer.position			= CGPoint( x: frame.width / 2, y: frame.height / 2 )
		_scrollView.showsVerticalScrollIndicator = false
		self.addSubview( _scrollView )
		
		_addButton							= UIButton( frame: CGRectMake( 0, 0, 30, 30 ) )
		_addButton.layer.anchorPoint		= CGPoint( x: 0.0, y: 0.5 )
		_addButton.layer.position			= CGPoint( x: _outerMergine, y: _outerMergine + _addButton.frame.height / 2 )
		_addButton.hidden					= !_enableEdit
		_addButton.titleLabel?.font			= _font
		_addButton.layer.masksToBounds		= true
		_addButton.userInteractionEnabled	= true
		_addButton.layer.cornerRadius		= _addButton.frame.height / 2
		_addButton.layer.borderColor		= _ddButtonTextColor.CGColor
		_addButton.layer.borderWidth		= 1.5
		_addButton.backgroundColor			= _addButtonBackgroundColor
		_addButton.setTitle( "+", forState: UIControlState.Normal )
		_addButton.setTitleColor( _ddButtonTextColor, forState: UIControlState.Normal )
		_addButton.setTitle( "+", forState: UIControlState.Highlighted )
		_addButton.setTitleColor( _ddButtonTextColor, forState: UIControlState.Highlighted )
		_addButton.setBackgroundImage( Utility.createImageFromColor( UIColor.whiteColor() ), forState: .Highlighted )
		_addButton.addTarget( self, action: #selector( onTapAddButton ), forControlEvents: .TouchUpInside )
		self.addSubview( _addButton )
	}
	
	// --------------------------------------------------------------------------------------------
	var enableEdit: Bool
	{
		get
		{
			return _enableEdit
		}
		set( newFlag )
		{
			if _addButton != nil
			{
				_addButton.hidden = !newFlag
			}
			_enableEdit = newFlag
		}
	}
	// --------------------------------------------------------------------------------------------
	func getTags() -> [String]
	{
		var tags: [String] = []
		for ( _, value ) in _tagFields.sort( { $0.0 < $1.0 } )
		{
			tags.append( value.text! )
		}
		return tags
	}

	// --------------------------------------------------------------------------------------------
	// layout functions
	// --------------------------------------------------------------------------------------------
	func addTag( position: CGPoint, tagString: String )
	{
		let tagField				= UITextField( frame: CGRectMake( 0, 0, 60, 30 ) )
		tagField.layer.anchorPoint	= CGPoint( x: 0.0, y: 0.0 )
		tagField.layer.position		= CGPoint( x: _outerMergine + position.x, y: _outerMergine + position.y )
		tagField.backgroundColor	= _tagBackgroundColor
		tagField.textColor			= _tagTextColor
		tagField.text				= tagString
		tagField.font				= _font
		tagField.textAlignment		= NSTextAlignment.Center
		tagField.delegate			= self
		tagField.borderStyle		= UITextBorderStyle.RoundedRect
		tagField.returnKeyType		= UIReturnKeyType.Done
		tagField.tag				= _tagIndex
		tagField.becomeFirstResponder()
		tagField.sizeToFit()
		_scrollView.addSubview( tagField )
		_tagFields[ _tagIndex ] = tagField
		fitTag( tagField )
		updateLayout()
		_tagIndex += 1
	}
	// --------------------------------------------------------------------------------------------
	func removeTag( tagField: UITextField )
	{
		_tagFields.removeValueForKey( tagField.tag )
		tagField.removeFromSuperview()
	}
	// --------------------------------------------------------------------------------------------
	func fitTag( tagField: UITextField )
	{
		if 0 < tagField.text!.characters.count
		{
			if ( tagField.text! as NSString ).substringToIndex( _tagPrefix.characters.count ) != _tagPrefix
			{
				tagField.text = _tagPrefix + tagField.text!
			}
		}
		tagField.sizeToFit()
		tagField.frame = CGRectMake( tagField.layer.position.x, tagField.layer.position.y, tagField.frame.width + _innerMergine * 2, tagField.frame.height + _innerMergine * 2 )
	}
	// --------------------------------------------------------------------------------------------
	func updateLayout()
	{
		_tagFieldMaxX = 0.0
		_tagFieldMinY = _outerMergine
		var tagFieldMaxY = CGFloat( 0.0 )
		for ( _, value ) in _tagFields.sort( { $0.0 < $1.0 } )
		{
			value.frame = CGRectMake( _tagFieldMaxX + _outerMergine, _tagFieldMinY, value.frame.width, value.frame.height )
			if frame.width - _outerMergine * 2 < value.frame.width
			{
				value.frame = CGRectMake( _outerMergine, value.frame.maxY + _outerMergine, frame.width - _outerMergine * 2, value.frame.height )
			}
			else if frame.width - _outerMergine < value.frame.maxX
			{
				value.layer.position = CGPoint( x: _outerMergine, y: value.frame.maxY + _outerMergine )
			}
			_tagFieldMaxX = value.frame.maxX
			_tagFieldMinY = value.frame.minY
			if tagFieldMaxY < value.frame.maxY
			{
				tagFieldMaxY = value.frame.maxY
			}
		}
		if _tagFields.count == 0
		{
			_addButton.layer.position = CGPoint( x: _outerMergine, y: _outerMergine + _addButton.frame.height / 2 )
		}
		else
		{
			_addButton.layer.position = CGPoint( x: _tagFieldMaxX + _outerMergine, y: _tagFieldMinY + ( tagFieldMaxY - _tagFieldMinY ) / 2 )
		}
		if frame.width - _outerMergine < _addButton.frame.maxX
		{
			_addButton.layer.position = CGPoint( x: _outerMergine, y: tagFieldMaxY + _outerMergine + _addButton.frame.height / 2 )
			if tagFieldMaxY < _addButton.frame.maxY
			{
				tagFieldMaxY = _addButton.frame.maxY
			}
		}
		_scrollView.contentSize = CGSizeMake( frame.width, tagFieldMaxY + _outerMergine )
		if _autoGlowHeight == true
		{
			frame = CGRectMake( _basePosition.x, _basePosition.y, _baseSize.width, max( _baseSize.height, _scrollView.contentSize.height ) )
			_scrollView.frame = CGRectMake( 0, 0, frame.width, frame.height )
		}
	}
	
	// --------------------------------------------------------------------------------------------
	// event functions
	// --------------------------------------------------------------------------------------------
	func onTapAddButton( sender: UIButton )
	{
		addTag( CGPoint( x: _tagFieldMaxX, y: _tagFieldMinY ), tagString: _tagPrefix )
	}
	// --------------------------------------------------------------------------------------------
	func textField( textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String ) -> Bool
	{
		NSTimer.scheduledTimerWithTimeInterval( 0.0, target: self, selector: #selector( onTimerTextField ), userInfo: _tagFields[ textField.tag ]!, repeats: false )
		return true
	}
	// --------------------------------------------------------------------------------------------
	func onTimerTextField( timer : NSTimer )
	{
		fitTag( timer.userInfo as! UITextField )
		updateLayout()
	}
	// --------------------------------------------------------------------------------------------
	func textFieldDidEndEditing( textField: UITextField )
	{
		if textField.text == "" || textField.text == _tagPrefix
		{
			removeTag( _tagFields[ textField.tag ]! )
		}
		else
		{
			fitTag( _tagFields[ textField.tag ]! )
		}
		updateLayout()
	}
	// --------------------------------------------------------------------------------------------
	func textFieldShouldReturn( textField: UITextField ) -> Bool
	{
		textField.resignFirstResponder()
		endEditing( true )
		delegate?.onDidEndEditing!( self )
		return true
	}
}


