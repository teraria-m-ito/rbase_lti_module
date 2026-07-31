# RBASE LTI_MODULE

- 業務アプリケーション基盤であるRBASE7 OSSに登録可能なプラグインモジュールです。
- RBASE7 OSSにLTI1.3によるアクセスを可能とします。
- LTI Advantageにも対応しており、DeepLinkやAGS、NRPSも対応しています。
- 本プラグインは、[1EdTech/lti-1-3-php-library](https://github.com/1EdTech/lti-1-3-php-library) を参考しRubyへ移植したコードを含みます。

 ## 利用方法

- 本プラグインを RBASE7 OSSのアプリルート/lib/customizesに配置します。
- rbase_plugins.ymlに本プラグインを定義します。
- rake rbase:plugins:symlinkを実行し、RABSE7 OSSの参照パスに展開します。

## 技術スタック（参考）

- Ruby **3.1.2**
- Rails **~> 7.0**

## ライセンス

本リポジトリのライセンスはリポジトリ直下の [LICENSE](LICENSE) を参照してください（GNU Affero General Public License v3）。
