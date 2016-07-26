#!/usr/bin/perl -w
use strict;
use Encode;
use JSON;
use Data::Dumper;
use URI::URL;
use URI::Escape;
my $dir = "/Users/mikeaalv/Documents/TCGA";


#initial and curl
my @project_ids = ("TCGA-READ","TCGA-BRCA","TCGA-COAD","TCGA-LUAD","TCGA-LUSC");    #should be project_id in TCGA
foreach my $project_id (@project_ids)
{
  system("mkdir "."$dir/$project_id");
  my $level = "open";
  my $flag = 0; #flag 0 download open data, flag 1 download all data, if you had the necessary access; information for open data for flag 1 will be the same as all
  my $filter = uri_escape("{\"op\":\"and\",\"content\":[{\"op\":\"in\",\"content\":{\"field\":\"cases.project.project_id\",\"value\":[\"".$project_id."\"]}}]}"); #for searching files or cases in this project
  #project information
  system("curl"." \'https://gdc-api.nci.nih.gov/projects/".$project_id."?expand=summary,summary.experimental_strategies,summary.data&pretty=true&format=TSV\' ".">$dir/".$project_id."/".$project_id."_project.tab");
  open(INPUT_project, $dir."/$project_id/$project_id"."_project.tab") or die "$!\n";
  my @project_info = <INPUT_project>;
  close(INPUT_project);
  my $i = 0;
  my @project_infor_arra = split("\t", $project_info[0]);
  foreach my $info_project (@project_infor_arra)#if this kind of cancer has the same result format as the hoped one
  {
    if($info_project =~ m/summary_file_count/ and !($info_project =~ m/\d/))
    {
        last;
    }
    $i += 1;
  }
  die "problem with finding the file count\n" if($i == scalar(@project_infor_arra));
  my @project_infor_arra_num = split("\t", $project_info[1]);
  my $file_num = $project_infor_arra_num[$i]; #number of files in the project
  $i = 0;
  foreach my $info_project (@project_infor_arra)#if this kind of cancer has the same result format as the hoped
  {
    if($info_project =~ m/summary_case_count/ and !($info_project =~ m/\d/))
    {
        last;
    }
    $i += 1;
  }
  die "problem with finding the case count\n" if($i == scalar(@project_infor_arra));
  my $case_num = $project_infor_arra_num[$i]; #number of cases in the project
  $i = 0;

  #whole statistics of files in the project
  system("curl"." \'https://gdc-api.nci.nih.gov/files?filters=".$filter."&size=".$file_num."&format=TSV&pretty=true&from=1&fields=data_type,updated_datetime,file_name,submitter_id,file_id,file_size,state_comment,acl_0,created_datetime,md5sum,data_format,access,platform,state,data_category,type,file_state,experimental_strategy,analysis.workflow_type\' ".">$dir/".$project_id."/".$project_id."_file.tab");
  open(INPUT_files, $dir."/$project_id/".$project_id."_file.tab") or die "$!\n";
  my $top_line = <INPUT_files>;
  my @contents = <INPUT_files>;
  close(INPUT_files);
  my %colum;  #location of information in the table
  my @UUID;
  my %barcode;    #uuid barcode relationship
  my %data_category;
  my %data_category_open;
  my %experimental_strategy;
  my %experimental_strategy_open;
  #statistics of methods for all data
  my %workflow_datatype;
  my %experimentalstragety_datatype;
  my @tops = split("\t", $top_line);
  $i = 0;
  #get the location of each information
  foreach my $top (@tops)
  {
    $colum{"access"} = $i if($top =~ m/access/);
    $colum{"data_category"} = $i if($top =~ m/data_category/);
    $colum{"experimental_strategy"} = $i if($top =~ m/experimental_strategy/);
    $colum{"workflow"} = $i if($top =~ m/analysis_workflow_type/);
    $i += 1
  }
  $i = 0;
  foreach my $line (@contents)    #statistics the open data and all data
  {
    my @a = split("\t", $line);
    chomp @a;
    #position without information
    $a[$colum{"data_category"}] = "NA" if ($a[$colum{"data_category"}] eq "");
    $a[$colum{"experimental_strategy"}] = "NA" if ($a[$colum{"experimental_strategy"}] =~ m/^[\r\n]*$/);    #experimental_strategy with trouble in the "next line"
    if(($a[$colum{"access"}] eq $level) or ($flag))
    {
        $i += 1;

        if(exists $data_category_open{$a[$colum{"data_category"}]} )
        {
            $data_category_open{$a[$colum{"data_category"}]} += 1;
        }
        else
        {
            $data_category_open{$a[$colum{"data_category"}]} = 1;
        }

        $a[$colum{"experimental_strategy"}] =~ s/[\r\n]*//g;
        if(exists $experimental_strategy_open{$a[$colum{"experimental_strategy"}]} )
        {
            $experimental_strategy_open{$a[$colum{"experimental_strategy"}]} += 1;
        }
        else
        {
            $experimental_strategy_open{$a[$colum{"experimental_strategy"}]} = 1;
        }

    }

    if(exists $data_category{$a[$colum{"data_category"}]} )
    {
        $data_category{$a[$colum{"data_category"}]} += 1;
    }
    else
    {
        $data_category{$a[$colum{"data_category"}]} = 1;
    }
    $a[$colum{"experimental_strategy"}] =~ s/[\r\n]*//g;
    if(exists $experimental_strategy{$a[$colum{"experimental_strategy"}]} )
    {
        $experimental_strategy{$a[$colum{"experimental_strategy"}]} += 1;
    }
    else
    {
        $experimental_strategy{$a[$colum{"experimental_strategy"}]} = 1;
    }
    if(exists $workflow_datatype{$a[$colum{"data_category"}]."&&".$a[$colum{"workflow"}]})
    {
      $workflow_datatype{$a[$colum{"data_category"}]."&&".$a[$colum{"workflow"}]} += 1;
    }
    else
    {
      $workflow_datatype{$a[$colum{"data_category"}]."&&".$a[$colum{"workflow"}]} = 1;
    }
    if(exists $experimentalstragety_datatype{$a[$colum{"data_category"}]."&&".$a[$colum{"experimental_strategy"}]})
    {
      $experimentalstragety_datatype{$a[$colum{"data_category"}]."&&".$a[$colum{"experimental_strategy"}]} += 1;
    }
    else
    {
      $experimentalstragety_datatype{$a[$colum{"data_category"}]."&&".$a[$colum{"experimental_strategy"}]} = 1;
    }
  }
  #statistics of all files
  open(OUTPUT_stat, ">".$dir."/$project_id/$project_id"."_statistics") or die "$!\n";
  print OUTPUT_stat "file_num: $file_num\topen: $i\n";
  $i = 0;
  print OUTPUT_stat "data_category: type_number\t".scalar(keys %data_category)."\n";
  print OUTPUT_stat join("\t",(keys %data_category))."\n";
  foreach my $key (keys %data_category)
  {
    print OUTPUT_stat $data_category{$key}."\t";
  }
  print OUTPUT_stat "\ndata_category_open: type_number\t".scalar(keys %data_category_open)."\n";
  print OUTPUT_stat join("\t",(keys %data_category))."\n";
  foreach my $key (keys %data_category)
  {
    if(exists $data_category_open{$key})
    {
        print OUTPUT_stat $data_category_open{$key}."\t";
    }
    else
    {
        print OUTPUT_stat "0\t";
    }
  }
  print OUTPUT_stat "\nexperimental_strategy: type_number\t".scalar(keys %experimental_strategy)."\n";
  print OUTPUT_stat join("\t",(keys %experimental_strategy))."\n";
  foreach my $key (keys %experimental_strategy)
  {
    print OUTPUT_stat $experimental_strategy{$key}."\t";
  }
  print OUTPUT_stat "\nexperimental_strategy_open: type_number\t".scalar(keys %experimental_strategy_open)."\n";
  print OUTPUT_stat join("\t",(keys %experimental_strategy))."\n";
  foreach my $key (keys %experimental_strategy)
  {
    if(exists $experimental_strategy_open{$key})
    {
        print OUTPUT_stat $experimental_strategy_open{$key}."\t";
    }
    else
    {
        print OUTPUT_stat "0\t";
    }
  }
  print OUTPUT_stat "\nworkflow for data category\n";
  foreach my $key (keys %data_category)
  {
    print OUTPUT_stat "$key:\t$data_category{$key}\n";
    foreach my $key_2 (keys %workflow_datatype)
    {
      if($key_2 =~ m/^$key\&\&/)
      {
        print OUTPUT_stat "$':".$workflow_datatype{$key_2}/$data_category{$key}."\t";
      }
    }
    print OUTPUT_stat "\n";
  }
  print OUTPUT_stat "\nexperimental stragety for data category\n";
  foreach my $key (keys %data_category)
  {
    print OUTPUT_stat "$key:\t$data_category{$key}\n";
    foreach my $key_2 (keys %experimentalstragety_datatype)
    {
      if($key_2 =~ m/^$key\&\&/)
      {
        print OUTPUT_stat "$':".$experimentalstragety_datatype{$key_2}/$data_category{$key}."\t";
      }
    }
    print OUTPUT_stat "\n";
  }

  $i = 0;
  #barcode uuid links
  open(OUTPUT_bar, ">".$dir."/$project_id/$project_id"."_barcode_uuid") or die "$!\n";
  print OUTPUT_bar "UUID\tbarcode\n";
  open(OUTPUT_relat_tree, ">".$dir."/$project_id/$project_id"."_case_relationship");
  print OUTPUT_relat_tree "$project_id\n";

  #statistics of files in each case and download according to the case
  my $case_rna_seq = 0;
  my $case_mirna_seq = 0;
  my $case_rna_mirna_seq = 0;
  system("curl"." \'https://gdc-api.nci.nih.gov/cases?filters=".$filter."&size=".$case_num."&format=TSV&pretty=true&from=1\' ".">$dir/".$project_id."/".$project_id."_case.tab");    #cases of each project
  open(INPUT_case, $dir."/$project_id/$project_id"."_case.tab") or die "$!\n";
  my $top_line_case = <INPUT_case>;
  my @contents_case = <INPUT_case>;
  close(INPUT_case);
  my @tops_cases = split("\t", $top_line_case);
  foreach my $top_case(@tops_cases)
  {
    if($top_case =~ m/case_id/)
    {
        last;
    }
    $i += 1;
  }
  $colum{"case_id"} = $i;
  $i = 0;

  foreach my $line_case(@contents_case)
  {
    my @b = split("\t",$line_case);
    my $case_id = $b[$colum{"case_id"}];
    #get file number in a case
    my $filter_case = uri_escape("{\"op\":\"and\",\"content\":[{\"op\":\"in\",\"content\":{\"field\":\"cases.case_id\",\"value\":[\"".$case_id."\"]}}]}");
    my @file_case_num = `curl \'https://gdc-api.nci.nih.gov/cases/$case_id?expand=summary,summary.experimental_strategies,summary.data_categories&pretty=true&format=TSV\'`;

    my @file_case_num_top = split("\t",$file_case_num[0]);
    $i = 0;
    foreach my $file_case_num_top_in (@file_case_num_top)
    {
        if($file_case_num_top_in =~ m/summary_file_count/)
        {
            last;
        }
        $i += 1;
    }
    die "error with file num in case\n" if($i == scalar(@file_case_num_top));
    my $file_num_in_case = $i;
    $i = 0;
    #get file information in a case
    my $file_case_uri = "curl"." \'https://gdc-api.nci.nih.gov/files?filters=".$filter_case."&size=".$file_num_in_case."&format=TSV&pretty=true&from=1\'";  #files of each case
    my @file_case = `$file_case_uri`;

    my @tops_case = split("\t",$file_case[0]);
    my %data_category_in_case;
    my %data_category_in_case_open;
    my %experimental_strategy_in_case;
    my %experimental_strategy_in_case_open;
    my %UUID_in_case;
    my %UUID_in_case_open;
    my %UUID_workflow_experimentalstragety;
    foreach my $top_case (@tops_case)
    {
        $colum{"access"} = $i if($top_case =~ m/access/);
        $colum{"data_category"} = $i if($top_case =~ m/data_category/);
        $colum{"experimental_strategy"} = $i if($top_case =~ m/experimental_strategy/);
        $colum{"UUID"} = $i if($top_case =~ m/file_id/);
        $colum{"workflow"} = $i if($top_case =~ m/files.analysis.workflow_type/);
        $i += 1;
    }
    open(INPUT_specimen, "/Users/mikeaalv/Documents/TCGA/biospecimen/biospecimen.tab") or die "$!\n";   #please change your locations accordingly
    <INPUT_specimen>;
    my @specimen = <INPUT_specimen>;
    close(INPUT_specimen);
    print OUTPUT_relat_tree "\ncase:$case_id\nbarcode\tdata category\n";
    foreach my $line (@specimen)
    {
      my @a_sp = split("\t", $line);
      chomp @a_sp;
      if($a_sp[0] eq $case_id)
      {
          my $filter_aliquo = uri_escape("{\"op\":\"and\",\"content\":[{\"op\":\"in\",\"content\":{\"field\":\"cases.samples.portions.analytes.aliquots.aliquot_id\",\"value\":[\"".$a_sp[1]."\"]}}]}");
          my $file_case_uri_aliquo = "curl"." \'https://gdc-api.nci.nih.gov/files?filters=".$filter_aliquo."&size=".$file_num_in_case."&format=TSV&pretty=true&from=1\'";  #files of each case
          my @file_case = `$file_case_uri_aliquo`;
          chomp @file_case;
          $file_case[0] =~ s/[\r\n]//g;
          if($file_case[0] ne "")
          {
            my $top_line = $file_case[0];
            my @b_sp = split("\t", $top_line);
            $i = 0;
            foreach my $ind_sp (@b_sp)
            {
              $colum{"file_id_sp"} = $i if($ind_sp =~ m/file_id/);
              $colum{"data_category_sp"} = $i if($ind_sp =~ m/data_category/);
              $colum{"experimental_strategy_sp"} = $i if($ind_sp =~ m/data_category/);
              $i += 1;
            }
            $i = 0;
            my %aliquot_data_cate;
            foreach my $line_sp (@file_case[1..(scalar(@file_case)-1)])
            {
              chomp $line_sp;
              my @b_line = split("\t", $line_sp);
              $aliquot_data_cate{$b_line[$colum{"data_category_sp"}]} = 1 if(!(exists $aliquot_data_cate{$b_line[$colum{"data_category_sp"}]}));
              $UUID_workflow_experimentalstragety{$b_line[$colum{"file_id_sp"}]} = "&1".$b_line[$colum{"data_category_sp"}]."&2".$b_line[$colum{"experimental_strategy_sp"}];
              print OUTPUT_bar $a_sp[2]."\t".$b_line[$colum{"file_id_sp"}]."\n";
            }
            my @aliquot_data_cate_array = keys %aliquot_data_cate;
            print OUTPUT_relat_tree $a_sp[2].":\t".join(";\t",@aliquot_data_cate_array)."\n";
          }
          else  #some aliquot without corresponding files
          {
            print OUTPUT_relat_tree $a_sp[2].":\tNONE"."\n";
          }
      }
    }

    $i = 0;

    foreach my $line_case (@file_case[1..(scalar(@file_case)-1)])    #statistics open data and all data
    {
        my @a = split("\t", $line_case);
        chomp @a;
        $a[$colum{"data_category"}] = "NA" if ($a[$colum{"data_category"}] eq "");
        $a[$colum{"experimental_strategy"}] = "NA" if ($a[$colum{"experimental_strategy"}] =~ m/^[\r\n]*$/);
        if(($a[$colum{"access"}] eq $level) or ($flag))
        {
            $UUID_in_case_open{$a[$colum{"UUID"}]} = $a[$colum{"data_category"}];
            push(@UUID, $a[$colum{"UUID"}]);
            if(exists $data_category_in_case_open{$a[$colum{"data_category"}]} )
            {
                $data_category_in_case_open{$a[$colum{"data_category"}]} += 1;
            }
            else
            {
                $data_category_in_case_open{$a[$colum{"data_category"}]} = 1;
            }
            $a[$colum{"experimental_strategy"}] =~ s/[\r\n]*//g;
            if(exists $experimental_strategy_in_case_open{$a[$colum{"experimental_strategy"}]} )
            {
                $experimental_strategy_in_case_open{$a[$colum{"experimental_strategy"}]} += 1;
            }
            else
            {
                $experimental_strategy_in_case_open{$a[$colum{"experimental_strategy"}]} = 1;
            }
        }
        $UUID_in_case{$a[$colum{"UUID"}]} = $a[$colum{"data_category"}];
        if(exists $data_category_in_case{$a[$colum{"data_category"}]} )
        {
            $data_category_in_case{$a[$colum{"data_category"}]} += 1;
        }
        else
        {
            $data_category_in_case{$a[$colum{"data_category"}]} = 1;
        }
        $a[$colum{"experimental_strategy"}] =~ s/[\r\n]*//g;
        if(exists $experimental_strategy_in_case{$a[$colum{"experimental_strategy"}]} )
        {
            $experimental_strategy_in_case{$a[$colum{"experimental_strategy"}]} += 1;
        }
        else
        {
            $experimental_strategy_in_case{$a[$colum{"experimental_strategy"}]} = 1;
        }
    }
    system("mkdir ".$dir."/".$project_id."/".$case_id);
    open(OUTPUT_case,">".$dir."/$project_id/$case_id/file_infor") or die "error in output case information";
    print OUTPUT_case "case_id:\t$case_id\n";
    print OUTPUT_case "UUID(open):\t".join("\t", keys %UUID_in_case_open)."\n\n";
    print OUTPUT_case "data_category\n".join("\t",(keys %data_category))."\n";
    foreach my $name_category (keys %data_category)
    {
        if(exists $data_category_in_case{$name_category})
        {
            print OUTPUT_case "$data_category_in_case{$name_category}\t";
        }
        else
        {
            print OUTPUT_case "0\t";
        }
    }
    print OUTPUT_case "\ndata_category_open\n".join("\t",(keys %data_category))."\n";
    foreach my $name_category (keys %data_category)
    {
        if(exists $data_category_in_case_open{$name_category})
        {
            print OUTPUT_case "$data_category_in_case_open{$name_category}\t";
        }
        else
        {
            print OUTPUT_case "0\t";
        }
    }
    print OUTPUT_case "\nexperimental_strategy\n".join("\t",(keys %experimental_strategy))."\n";
    foreach my $name_experiment (keys %experimental_strategy)
    {
        $name_experiment =~ s/[\r\n]*//g;
        if(exists $experimental_strategy_in_case{$name_experiment})
        {
            print OUTPUT_case "$experimental_strategy_in_case{$name_experiment}\t";
        }
        else
        {
            print OUTPUT_case "0\t";
        }
    }
    $case_rna_seq += 1 if(exists $experimental_strategy_in_case{"RNA-Seq"});
    $case_mirna_seq += 1 if(exists $experimental_strategy_in_case{"miRNA-Seq"});
    $case_rna_mirna_seq += 1 if(exists $experimental_strategy_in_case{"RNA-Seq"} and exists $experimental_strategy_in_case{"miRNA-Seq"});

    print OUTPUT_case "\nexperimental_strategy_open\n".join("\t",(keys %experimental_strategy))."\n";
    foreach my $name_experiment (keys %experimental_strategy)
    {
        $name_experiment =~ s/[\r\n]*//g;
        if(exists $experimental_strategy_in_case_open{$name_experiment})
        {
            print OUTPUT_case "$experimental_strategy_in_case_open{$name_experiment}\t";
        }
        else
        {
            print OUTPUT_case "0\t";
        }
    }
    close(OUTPUT_case);
    #gdc-client if you don't have enough storage and internet, don't do the following
    system("mkdir ".$dir."/".$project_id."/".$case_id."/data");
    print "DOWNLOADing data of case $case_id\n";
    foreach my $uuid (keys %UUID_in_case_open)
    {
      my $action = "";
      system("mkdir "."$dir/$project_id/$case_id/data/Clinical") if(!(-e "$dir/$project_id/$case_id/data/Clinical"));
      system("mkdir "."$dir/$project_id/$case_id/data/SNV") if(!(-e "$dir/$project_id/$case_id/data/SNV"));
      system("mkdir "."$dir/$project_id/$case_id/data/Transcriptome") if(!(-e "$dir/$project_id/$case_id/data/Transcriptome"));
      system("mkdir "."$dir/$project_id/$case_id/data/CNV") if(!(-e "$dir/$project_id/$case_id/data/CNV"));
      system("mkdir "."$dir/$project_id/$case_id/data/biospecimen") if(!(-e "$dir/$project_id/$case_id/data/biospecimen"));
      $action = "gdc-client "."download ".$uuid." -d ".$dir."/".$project_id."/".$case_id."/data/clinical" if($UUID_in_case_open{$uuid} =~ m/[Cc]linical/);
      #$action = "gdc-client "."download ".$uuid." -d ".$dir."/".$project_id."/".$case_id."/data/SNV" if($UUID_in_case_open{$uuid} =~ m/[Ss]imple [Nn]ucleotide [Vv]ariation/);
      #$action = "gdc-client "."download ".$uuid." -d ".$dir."/".$project_id."/".$case_id."/data/Transcriptome" if($UUID_in_case_open{$uuid} =~ m/[Tt]ranscriptome [pP]rofiling/);
      #$action = "gdc-client "."download ".$uuid." -d ".$dir."/".$project_id."/".$case_id."/data/raw" if($UUID_in_case_open{$uuid} =~ m/[Rr]aw [Ss]equencing [Dd]ata/);
      #$action = "gdc-client "."download ".$uuid." -d ".$dir."/".$project_id."/".$case_id."/data/CNV" if($UUID_in_case_open{$uuid} =~ m/[cC]opy [Nn]umber [Vv]ariation/);
      #$action = "gdc-client "."download ".$uuid." -d ".$dir."/".$project_id."/".$case_id."/data/biospecimen" if($UUID_in_case_open{$uuid} =~ m/[Bb]iospecimen/);
      if($action ne "")
      {
        my $out_gdc = `$action`;
        $out_gdc =~ m/^((Downloading)|(Checksumming))\s+(?<file>([\w\.-]+))\s*\(/;
        my $filename = $+{file};
        #system("mv ".$dir."/".$project_id."/".$case_id."/data/SNV".$filename." ".$dir."/".$project_id."/".$case_id."/data/SNV".$filename.$UUID_workflow_experimentalstragety{$uuid}) if($UUID_in_case_open{$uuid} =~ m/[Ss]imple [Nn]ucleotide [Vv]ariation/);
        #system("mv ".$dir."/".$project_id."/".$case_id."/data/Transcriptome".$filename." ".$dir."/".$project_id."/".$case_id."/data/Transcriptome".$filename.$UUID_workflow_experimentalstragety{$uuid}) if($UUID_in_case_open{$uuid} =~ m/[Tt]ranscriptome [pP]rofiling/);
        #system("mv ".$dir."/".$project_id."/".$case_id."/data/raw".$filename." ".$dir."/".$project_id."/".$case_id."/data/raw".$filename.$UUID_workflow_experimentalstragety{$uuid}) if($UUID_in_case_open{$uuid} =~ m/[Rr]aw [Ss]equencing [Dd]ata/);
        #system("mv ".$dir."/".$project_id."/".$case_id."/data/CNV".$filename." ".$dir."/".$project_id."/".$case_id."/data/CNV".$filename.$UUID_workflow_experimentalstragety{$uuid}) if($UUID_in_case_open{$uuid} =~ m/[cC]opy [Nn]umber [Vv]ariation/);
        #system("mv ".$dir."/".$project_id."/".$case_id."/data/biospecimen".$filename." ".$dir."/".$project_id."/".$case_id."/data/biospecimen".$filename.$UUID_workflow_experimentalstragety{$uuid}) if($UUID_in_case_open{$uuid} =~ m/[Bb]iospecimen/);
    }
  #  foreach my $uuid (keys %UUID_in_case){}
  }
}
print OUTPUT_stat "cases with RNA-seq:\t".$case_rna_seq."\n";
print OUTPUT_stat "case with miRNA-Seq:\t".$case_mirna_seq."\n";
print OUTPUT_stat "case with miRNA-Seq and RNA-Seq:\t".$case_rna_mirna_seq."\n";
close(OUTPUT_stat);
close(OUTPUT_relat_tree);
close(OUTPUT_bar);
}
