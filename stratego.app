module webdsl-lib-stratego

type String{
  org.webdsl.tools.strategoxt.ATerm.toATerm as parseATerm(): ATerm
}

native class org.spoofax.interpreter.terms.IStrategoTerm as ATerm{
  org.webdsl.tools.strategoxt.ATerm.subterms as subterms(): [ATerm]
  org.webdsl.tools.strategoxt.ATerm.constructor as cons(): String
  org.webdsl.tools.strategoxt.ATerm.stringValue as stringValue(): String
  org.webdsl.tools.strategoxt.ATerm.get as get( Int ): ATerm
  org.webdsl.tools.strategoxt.ATerm.length as length(): Int
  org.webdsl.tools.strategoxt.ATerm.toString as toString(): String
  org.webdsl.tools.strategoxt.ATerm.toInt as toInt(): Int
}

template output( a: ATerm ){
  text( a.toString() )
}

native class org.webdsl.tools.strategoxt.StrategoProgram as Stratego{
  static get( String ): Stratego
  invoke( String, ATerm ): ATerm
  invoke( String, String ): ATerm
}

native class org.webdsl.tools.strategoxt.SDF as SDF{
  static get( String ): SDF
  isValid( String ): Bool
  getSGLRError( String ): String
  parse( String ):ATerm
}

function checkSDFWellformedness( req: String, language: String ): [String]{
  var errors: [String] := null;
  if(    req != null
      && ! SDF.get( language ).isValid( req )
  ){
    errors := [ SDF.get( language ).getSGLRError( req ) ];
  }
  return errors;
}

template inputSDF( s: ref Text, language: String ){
  var req := getRequestParameter( id )

  request var errors: [String] := null

  if( errors != null && errors.length > 0 ){
    errorTemplateInput( errors ){
      inputTextInternal( s, id )[ inputSDF attributes, all attributes ]
    }
    validate{ getPage().enterLabelContext( id ); }
    elements
    validate{ getPage().leaveLabelContext(); }
  }
  else{
    inputTextInternal( s, id )[ inputSDF attributes, all attributes ]
    validate{ getPage().enterLabelContext( id ); }
    elements
    validate{ getPage().leaveLabelContext(); }
  }
  validate{
    if(    req != null 
        && ! SDF.get( language ).isValid( req )
    ){
      errors := [ SDF.get( language ).getSGLRError( req ) ];
    }
    if( errors == null ){ // if no wellformedness errors, check datamodel validations
      errors := s.getValidationErrors();
      errors.addAll( getPage().getValidationErrorsByName( id ) ); //nested validate elements
    }
    errors := handleValidationErrors( errors );
  }
}

template inputSDFajax( s: ref Text, language: String ){
  var req := getRequestParameter( id )
  request var errors: [String] := null
  inputTextInternal( s, id )[ inputSDF attributes
                            , oninput = validator(); "" + attribute("oninput")
                            , all attributes except "oninput" ]
  validate{ getPage().enterLabelContext( id ); }
  elements
  validate{ getPage().leaveLabelContext(); }
  placeholder "validate" + id{
    if( errors != null && errors.length > 0 ){
      showMessages(errors)
    }
  }
  validate{
    errors := checkSDFWellformedness( req, language );
    if( errors == null ){
      errors := s.getValidationErrors();
      errors.addAll( getPage().getValidationErrorsByName( id ) );
    }
    if( errors.length > 0 ){
      cancel();
    }
  }
  action ignore-validation validator(){
    errors := checkSDFWellformedness( req, language );
    if( errors == null ){
      errors := s.getValidationErrors();
      getPage().enterLabelContext( id );
      validatetemplate( elements );
      getPage().leaveLabelContext();
      errors.addAll( getPage().getValidationErrorsByName( id ) );
    }
    if( errors.length > 0 ){
      replace( "validate" + id, showMessages( errors ) );
    }
    else{
      replace( "validate" + id, noMessages() );
    }
    rollback();
  }
}
