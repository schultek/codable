
Augmentation versions generally work except for:
------------------------------------------------------

generics/basic/model
  box.dart                 // SEE NOTES in these files
  box.codable.dart         // augment versions can cause CRASHES in analyzer and cause weird errors in the analyzer


polymorphism/complex/model
   box.dart                  // SEE NOTES in these files
   box.codable.dart          // augment versions can cause CRASHES in analyzer OR cause the weird analyzer errors





--------

And currently (2/3/2025) the compiler is completely broken for the `augment` key word and nothing compiles (or even formats)

I have filed 
   https://github.com/dart-lang/sdk/issues/60039

to detail the bug in the `augment` keyword


#Files used for sdk bug report issues:
----------------------------------------------------------
test\augment_test\basic\model\superbasic_for_issue_bug_report.dart  
stand alone code create for https://github.com/dart-lang/sdk/issues/60039


test\augment_test\generics\basic\model\standalone_error.dart   
Stand alone code created for https://github.com/dart-lang/sdk/issues/60040

